#!/usr/bin/env bash
set -euo pipefail

root="${1}"

for dataset in $(zfs list -H -r -o name "${root}" | grep -v "^${root}$"); do
	echo ">>> Dataset '${dataset}'"
	./backup.sh "${dataset}"
done
