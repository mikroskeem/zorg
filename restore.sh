#!/usr/bin/env bash
set -euo pipefail

scriptdir="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
source "${scriptdir}/common.sh"

repo=""
dataset=""

while [ -n "${1:-}" ]; do
	arg="${1}"
	case "${arg}" in
		--repo)
			shift
			repo="${1}"
			;;
		--dataset)
			shift
			dataset="${1}"
			;;
		*)
			echo ">>> Unknown arg '${arg}'"
			exit 2
			;;
	esac
	shift
done

[ -d "${scriptdir}/repos/${repo}" ] || {
	echo ">>> No such repository '${repo}'"
	exit 1
}

[ -n "${dataset}" ]
dataset_exists "${dataset}" && {
	echo ">>> Dataset '${dataset}' already exists!"
	exit 1
}

process_list () {
	jq '.archives[] | {archive: .archive, data: (.comment | split(":") | if .[0] == "json" then (.[1] | @base64d | fromjson) else null end)}'
}

zfs create "${dataset}" || true

# We always want to match uid/gid from the archives
export ZORG_REMAP_READONLY=false
export ZORG_REMAP_WRITE_NO_REMAP=true

"${scriptdir}/list.sh" "${repo}" | process_list | jq -r '"\(.archive)\t\(.data.snapshot)"' | while read -r -a data; do
	archive="${data[0]}"
	snapshot="${data[1]}"

	"${scriptdir}/mount_remap.sh" "${dataset}" \
		"${scriptdir}/with_repo_mount.sh" "${repo}" "${archive}" /tmp/archive \
		rsync -axv /tmp/archive/ .

	zfs snapshot "${dataset}@${snapshot}"
done