#!/usr/bin/env bash
set -euo pipefail

scriptdir="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
source "${scriptdir}/common.sh"

repo="${1}"
archive="${2}"
target="${3}"
shift 3

if [ -z "${*}" ]; then
        echo ">>> No command specified"
        exit 1
fi

if ! [ -d "${scriptdir}/repos/${repo}" ]; then
	echo ">>> No such repository '${repo}'"
	exit 1
fi

mkdir -p "${target}"
"${scriptdir}/with_repo.sh" "${repo}" borg mount -f -o ignore_permissions ::"${archive}" "${target}" &
bpid="${!}"

cleanup () {
	umount "${target}" || kill -9 "${bpid}"
	wait "${bpid}"
}
trap 'cleanup' EXIT

while [ -z "$(awk -v "mnt=${target}" '$2 == mnt { print $2 }' /proc/mounts)" ]; do
        sleep 0.5
done

"${@}"
