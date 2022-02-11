#!/usr/bin/env bash
set -euo pipefail

scriptdir="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
repo="${1}"

[ -d "${scriptdir}/repos/${repo}" ] && exec -- "${scriptdir}/with_env.sh" "${repo}" borg list --json --format "{comment}"
