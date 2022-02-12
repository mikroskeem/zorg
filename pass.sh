#!/usr/bin/env bash
set -euo pipefail

: "${ZORG_SSH_KEY}"

scriptdir="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
source "${scriptdir}/common.sh"

repo="${1}"
selector=""
case "${2}" in
	passphrase)
		selector=".passphrase"
		;;
	key)
		selector=".key"
		;;
esac

[ -n "${selector}" ]

credsdir="$(creds_dir "${repo}")"

rage -i "${ZORG_SSH_KEY}" -d "${credsdir}/creds.json.age" | jq -r "${selector}" | base64 -d
