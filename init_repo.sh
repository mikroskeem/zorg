#!/usr/bin/env bash
set -euo pipefail

# Initializes a repository with automatically generated passphrase, which
# gets encrypted by rage using SSH key

scriptdir="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
source "${scriptdir}/common.sh"

repo_name="${1}"
remote="${2:-}"

repodir="${scriptdir}/repos/${repo_name}"
credsdir="$(creds_dir "${repo_name}")"

if [ -d "${credsdir}" ]; then
	echo ">>> Credentials for '${repo_name}' already exist, bailing out."
	exit 1
fi

repo="${repodir}"
repodir_data="${repodir}.remote"
if [ -n "${remote}" ]; then
	repo="${remote}"
	echo "${repo}" > "${repodir_data}"
fi
mkdir -p "$(dirname -- "${repodir_data}")"

_borgdir="$(mktemp -d)"
cleanup_borgdir () {
	rm -rf "${_borgdir}" || true
}
cleanup_hooks+=(cleanup_borgdir)

export BORG_BASE_DIR="${_borgdir}"
passphrase="$(gpg --gen-random --armor 2 128)"
keyfile="${_borgdir}/repo/key"

unset BORG_NEW_PASSPRHASE
export BORG_PASSPHRASE="${passphrase}"
borg init --error --make-parent-dirs --encryption=keyfile-blake2 "${repo}"
borg key export "${repo}" /dev/stdout | write_file 400 "${keyfile}"

credsjson="$(jq -c <<EOF
{ "passphrase": "$(base64 -w 0 <<< "${passphrase}")"
, "key": "$(base64 -w 0 < "${keyfile}")"
}
EOF
)"

mkdir -p "${credsdir}"
encrypt_key "${credsdir}" <<< "${credsjson}"
