#!/usr/bin/env bash
set -euo pipefail

scriptdir="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
source "${scriptdir}/common.sh"

repo_name="${1}"
repodir="${scriptdir}/repos"
repo="$(resolve_repo_dir "${repodir}" "${repo_name}")"

[ -n "${repo}" ] && "${scriptdir}/with_repo.sh" "${repo_name}" borg list --json --format "{comment}"
