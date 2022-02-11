#!/usr/bin/env bash
set -euo pipefail

root="${1}"
scriptdir="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
zfs list -H -r -p -o name "${root}" | grep -v "^${root}$" | while read -r dataset; do
	snapshots="$(zfs list -H -r -p -t snapshot -o name "${dataset}" 2>/dev/null | cut -d@ -f 2-)"
	if ! grep -q -v -x -E -f "${scriptdir}/ignored.txt" <<< "${snapshots}"; then
		echo "${dataset}"
	fi
done
