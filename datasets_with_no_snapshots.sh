#!/usr/bin/env bash
set -euo pipefail

# Due to the way how zorg works, you *need* at least one snapshot to back up
# the dataset. This helps you to find datasets which do not have any snapshots.

scriptdir="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"

root="${1}"
zfs list -H -r -p -o name "${root}" | grep -v "^${root}$" | while read -r dataset; do
	snapshots="$(zfs list -H -r -p -t snapshot -o name "${dataset}" 2>/dev/null | cut -d@ -f 2-)"
	if [ -z "${snapshots}" ] || ! grep -q -v -x -E -f "${scriptdir}/ignored.txt" <<< "${snapshots}"; then
		echo "${dataset}"
	fi
done
