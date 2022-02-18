#!/usr/bin/env bash
set -euo pipefail

scriptdir="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
source "${scriptdir}/common.sh"

repo="${1}"
credsdir="$(creds_dir "${repo}")"
current_type="$(_determine_key_prog "${credsdir}")"

new_credsdir="$(dirname -- "${credsdir}")/.$(basename -- "${credsdir}").${RANDOM}"
new_type="${2:-"${current_type}"}"

[ -n "${credsdir}" ]
[ -n "${new_credsdir}" ]
[ -n "${new_type}" ]

mkdir -p "${new_credsdir}"

cleanup () {
	if [ -d "${new_credsdir}" ]; then
		rm -rf "${new_credsdir}"
	fi
}

trap 'cleanup' EXIT

decrypt_key "${credsdir}" | encrypt_key "${new_credsdir}" "${new_type}"
rm -rf "${credsdir}"
mv "${new_credsdir}" "${credsdir}"
