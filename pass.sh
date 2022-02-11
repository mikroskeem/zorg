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

rage -i ~/.ssh/backup_key_ed25519 -d "${creds}/creds.json.age" | jq -r "${selector}" | base64 -d
