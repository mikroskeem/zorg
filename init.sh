#!/usr/bin/env bash
set -euo pipefail

: "${ZORG_SSH_KEY}"

scriptdir="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
source "${scriptdir}/common.sh"

repo="${1}"
repodir="${scriptdir}/repos/${repo}"
credsdir="$(creds_dir "${repo}")"

if [ -d "${credsdir}" ]; then
	echo ">>> Credentials for '${repo}' already exist, bailing out."
	exit 1
fi

_borgdir="$(mktemp -d)"
cleanup () {
	rm -rf "${_borgdir}" || true
}
trap 'cleanup' EXIT

export BORG_BASE_DIR="${_borgdir}"
passphrase="$(gpg --gen-random --armor 2 128)"
keyfile="${_borgdir}/repo/key"

export BORG_PASSPHRASE="${passphrase}"
borg init --error --make-parent-dirs --encryption=keyfile-blake2 "${repodir}"
borg key export "${repodir}" /dev/stdout | install -D -m 400 /dev/stdin "${keyfile}"

credsjson="$(jq -c <<EOF
{ "passphrase": "$(base64 -w 0 <<< "${passphrase}")"
, "key": "$(base64 -w 0 < "${keyfile}")"
}
EOF
)"

mkdir -p "${credsdir}"
rage -i "${ZORG_SSH_KEY}" -e -o "${credsdir}/creds.json.age" <<< "${credsjson}"
