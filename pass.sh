#!/usr/bin/env bash
set -euo pipefail

: "${ZORG_SSH_KEY}"

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

scriptdir="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
creds="${scriptdir}/creds/${repo}"

rage -i "${ZORG_SSH_KEY}" -d "${creds}/creds.json.age" | jq -r "${selector}" | base64 -d
