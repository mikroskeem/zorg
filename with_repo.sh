#!/usr/bin/env bash
set -euo pipefail

# Sets up environment variables and credentials for borg to open a repository.
# If repository does not exist on disk, then it'll be initialized from scratch using
# init_repo.sh script.

repo="${1}"
shift

: "${ZORG_USE_BORG_CACHE:=0}"

scriptdir="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
repodir="${scriptdir}/repos"

_borgdir="$(mktemp --tmpdir -d borghome."${USER}".XXXXXXX)"

cleanup () {
	rm -rf "${_borgdir}" || true
}

trap 'cleanup' EXIT


test -d "${repodir}/${repo}" || "${scriptdir}/init_repo.sh" "${repo}"
"${scriptdir}/pass_repo.sh" "${repo}" key | install -D -m 400 /dev/stdin "${_borgdir}/repo/key"


if [ "${ZORG_USE_BORG_CACHE}" = "1" ]; then
	cachedir="${scriptdir}/cache"
	mkdir -p "${cachedir}"
	export BORG_CACHE_DIR="${cachedir}"
fi

export BORG_PASSCOMMAND="${scriptdir}/pass_repo.sh '${repo}' passphrase"
export BORG_KEY_FILE="${_borgdir}/repo/key"
export BORG_BASE_DIR="${_borgdir}"
export BORG_REPO="${repodir}/${repo}"
export BORG_SELFTEST="disabled"

"${@}"
