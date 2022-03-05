#!/usr/bin/env bash
set -euo pipefail

# Mounts a dataset (or snapshot) into its own user & mount namespace, remapping fs uid/gid using
# bindfs and running target program without real root privileges.
# This allows backups to be so-called uid/gid-neutral and reproducible.

scriptdir="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
source "${scriptdir}/common.sh"

elevate=()
if [ "${UID}" -ne 0 ]; then
	elevate+=(sudo --)
fi

: "${ZORG_REMAP_READONLY:=true}"
: "${ZORG_REMAP_WRITE_NO_BINDFS:=false}"

if [ -z "${_IN_NS:-}" ]; then
	# shellcheck disable=SC2046
	exec -- "${elevate[@]}" unshare -m -f -p \
		--kill-child --mount-proc \
		-- \
		$(propagate_env _IN_NS=1 _NS_UID="$(id -u)" _NS_GID="$(id -g)") "${0}" "${@}"
fi

dataset="${1}"
if ! dataset_exists "${dataset}"; then
	echo ">>> No such dataset: ${dataset}"
	exit 1
fi

shift
if [ -z "${*}" ]; then
	echo ">>> No command specified"
	exit 1
fi

mnt_final=""
mountflags=()
is_dataset=1
if grep -q "@" <<< "${dataset}"; then
	IFS=@ read -r -a _snapshot <<< "${dataset}"
	_dataset="${_snapshot[0]}"
	_snap="${_snapshot[1]}"
	mnt_final="/tmp/${_snap}"
	is_dataset=0
else
	# work around zfs annoying mount mechanism
	if ! [ "$(zfs get -H -o value mountpoint "${dataset}")" = "legacy" ]; then
		mountflags+=(zfsutil)
	fi
	if [ "${ZORG_REMAP_READONLY}" = "true" ]; then
		mountflags+=(ro)
	fi
	mnt_final="/tmp/$(basename -- "${dataset}")"
fi

mount -t tmpfs tmpfs /tmp
if (( is_dataset )) && ! [ "${ZORG_REMAP_READONLY}" = "true" ] && [ "${ZORG_REMAP_WRITE_NO_BINDFS}" = "true" ]; then
	mkdir -p "${mnt_final}"
	mount -t zfs -o "$(IFS=,; echo "${mountflags[*]}")" "${dataset}" "${mnt_final}"
else
	mnt_dataset="/tmp/.real/dataset"
	mkdir -p "${mnt_dataset}" "${mnt_final}"

	mount -t zfs -o "$(IFS=,; echo "${mountflags[*]}")" "${dataset}" "${mnt_dataset}"
	bindfs -u "${_NS_UID}" -g "${_NS_GID}" "${mnt_dataset}" "${mnt_final}" -f &
	bpid="${!}"

	cleanup () {
		umount "${mnt_final}" || kill -9 "${bpid}"
		wait "${bpid}"
	}
	trap 'cleanup' EXIT
fi

#findmnt --poll=mount --first-only --timeout=$((10 * 1000)) --mountpoint "${mnt_final}" # TODO: crashes with double free???
while [ -z "$(awk -v "mnt=${mnt_final}" '$2 == mnt { print $2 }' /proc/mounts)" ]; do
	sleep 0.5
done

# shellcheck disable=SC2046
setpriv --reuid="${_NS_UID}" --regid="${_NS_GID}" --init-groups --reset-env \
	$(propagate_env) unshare -U -r --wd="${mnt_final}" -- "${@}"
