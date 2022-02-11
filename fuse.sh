#!/usr/bin/env bash
set -euo pipefail

elevate=()
if [ "${UID}" -ne 0 ]; then
	elevate+=(sudo --)
fi

if [ -z "${_IN_NS:-}" ]; then
	exec -- "${elevate[@]}" unshare -m -f -p \
		--kill-child --mount-proc \
		-- \
		env _IN_NS=1 _NS_UID="$(id -u)" _NS_GID="$(id -g)" "${0}" "${@}"
fi


snapshot="${1}"
shift
if [ -z "${*}" ]; then
	echo ">>> No command specified"
	exit 1
fi

IFS=@ read -r -a _snapshot <<< "${snapshot}"
_dataset="${_snapshot[0]}"
_snap="${_snapshot[1]}"

mount -t tmpfs tmpfs /tmp

mnt_snap=/tmp/.real/snap
mnt_final=/tmp/"${_snap}"

mkdir -p "${mnt_snap}" "${mnt_final}"

mount -t zfs "${snapshot}" "${mnt_snap}"
bindfs -u "${_NS_UID}" -g "${_NS_GID}" "${mnt_snap}" "${mnt_final}" -f &
bpid="${!}"

cleanup () {
	umount "${mnt_final}" || kill -9 "${bpid}"
	wait "${bpid}"
}
trap 'cleanup' EXIT

#findmnt --poll=mount --first-only --timeout=$((10 * 1000)) --mountpoint "${mnt_final}" # TODO: crashes with double free???
while [ -z "$(awk -v "mnt=${mnt_final}" '$2 == mnt { print $2 }' /proc/mounts)" ]; do
	sleep 0.5
done

setpriv --reuid="${_NS_UID}" --regid="${_NS_GID}" --init-groups --reset-env \
	env PATH="${PATH}" unshare -U -r --wd="${mnt_final}" -- "${@}"
