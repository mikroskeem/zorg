#!/usr/bin/env bash
set -euo pipefail

# Sets up environment variables and credentials for borg to open a repository.
# If repository does not exist on disk, then it'll be initialized from scratch using
# init_repo.sh script.

repo_name="${1}"
shift

: "${ZORG_USE_BORG_CACHE:=0}"

scriptdir="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
source "${scriptdir}/common.sh"

repodir="${scriptdir}/repos"

_borgdir="$(mktemp --tmpdir -d borghome."${USER}".XXXXXXX)"

cleanup () {
	rm -rf "${_borgdir}" || true
}

trap 'cleanup' EXIT

repo="$(resolve_repo_dir "${repodir}" "${repo_name}")"
if [ -z "${repo}" ]; then
	"${scriptdir}/init_repo.sh" "${repo_name}"
	repo="$(resolve_repo_dir "${repodir}" "${repo_name}")"
	[ -n "${repo}" ]
fi

"${scriptdir}/pass_repo.sh" "${repo_name}" key | write_file 400 "${_borgdir}/repo/key"


if [ "${ZORG_USE_BORG_CACHE}" = "1" ]; then
	cachedir="${scriptdir}/cache"
	mkdir -p "${cachedir}"
	export BORG_CACHE_DIR="${cachedir}"
fi

export BORG_PASSCOMMAND="${scriptdir}/pass_repo.sh '${repo_name}' passphrase"
export BORG_KEY_FILE="${_borgdir}/repo/key"
export BORG_BASE_DIR="${_borgdir}"
export BORG_REPO="${repo}"
export BORG_SELFTEST="disabled"

"${@}"
