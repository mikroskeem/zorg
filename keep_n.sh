#!/usr/bin/env bash
set -euo pipefail

n="${1}"
ds="${2}"

if ! (( $n >= 0 )); then
	echo "n must be ge 0 (was '${n}')"
	exit 1
fi

zfs list -H -t snapshot -p -o name -s creation "${ds}" | head -n -"${n}" | while read -r dataset; do
	echo "destroying ${dataset}"
	sudo zfs destroy "${dataset}"
done
