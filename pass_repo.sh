#!/usr/bin/env bash
set -euo pipefail

if ! [ -f "${ZORG_SSH_KEY}" ]; then
	echo ">>> ZORG_SSH_KEY does not exist"
	exit 1
fi

scriptdir="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
source "${scriptdir}/common.sh"

repo="${1}"
selector="${2}"
credsdir="$(creds_dir "${repo}")"

case "${selector}" in
	passphrase)
		selector=".passphrase"
		;;
	key)
		selector=".key"
		;;
	*)
		echo >&2 "Unsupported selector '${selector}'"
		exit 1
		;;
esac


decrypt_key "${credsdir}" | jq -r "${selector}" | base64 -d
