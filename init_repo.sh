#!/usr/bin/env bash
set -euo pipefail

# Initializes a repository with automatically generated passphrase, which
# gets encrypted by rage using SSH key

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

unset BORG_NEW_PASSPRHASE
export BORG_PASSPHRASE="${passphrase}"
borg init --error --make-parent-dirs --encryption=keyfile-blake2 "${repodir}"
borg key export "${repodir}" /dev/stdout | write_file 400 "${keyfile}"

credsjson="$(jq -c <<EOF
{ "passphrase": "$(base64 -w 0 <<< "${passphrase}")"
, "key": "$(base64 -w 0 < "${keyfile}")"
}
EOF
)"

mkdir -p "${credsdir}"
encrypt_key "${credsdir}" <<< "${credsjson}"
