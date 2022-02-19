#!/usr/bin/env bash
set -euo pipefail

scriptdir="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
source "${scriptdir}/common.sh"

repo="${1}"

if ! [ -d "${scriptdir}/repos/${repo}" ]; then
	echo ">>> Repository '${repo}' does not exist"
	exit 1
fi

credsdir="$(creds_dir "${repo}")"

new_passphrase="${2:-}"
if [ "${new_passphrase}" = "-" ] || [ "${new_passphrase}" = "/dev/stdin" ]; then
	new_passphrase="$(< /dev/stdin)"
elif [ -e "${new_passphrase}" ]; then
	new_passphrase="$(< "${new_passphrase}")"
elif [ -z "${new_passphrase}" ]; then
	while [ -z "${new_passphrase}" ]; do
		read -r -p "New passphrase: " new_passphrase
	done
fi

export BORG_NEW_PASSPHRASE="${new_passphrase}"
new_key="$("${scriptdir}/with_repo.sh" "${repo}" bash -euc 'borg key change-passphrase 1>&2 && borg key export :: /dev/stdout')"

# Write new credentials
decrypt_key "${credsdir}" \
	| jq --rawfile passfd <(base64 -w 0 <<<"${new_passphrase}") -c '.passphrase = $passfd' \
	| jq --rawfile keyfd <(base64 -w 0 <<<"${new_key}") -c '.key = $keyfd' \
	| encrypt_key "${credsdir}"
