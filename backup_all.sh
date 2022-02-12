#!/usr/bin/env bash
set -euo pipefail

scriptdir="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
source "${scriptdir}/common.sh"

root="${1}"

for dataset in $(zfs list -H -p -r -o name "${root}" | grep -v "^${root}$"); do
	decho ">>> Dataset '${dataset}'"
	./backup.sh "${dataset}"
done
