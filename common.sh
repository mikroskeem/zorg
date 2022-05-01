# shellcheck shell=bash
# shellcheck disable=SC2034,SC2154 # parent scripts define this
: "${scriptdir}"

default_key_prog="${ZORG_KEY_PROG}"

: "${BORG_RSH:=ssh}"
: "${BORG_RELOCATED_REPO_ACCESS_IS_OK:=yes}"
: "${SOPS_GPG_KEYSERVER:=keys.openpgp.org}"
export SOPS_GPG_KEYSERVER

propagated_envvars=(
	PATH
	BORG_RELOCATED_REPO_ACCESS_IS_OK
	BORG_REMOTE_PATH
	BORG_RSH
	GNUPGHOME
	GPG_TTY
	ZORG_DEBUG
	ZORG_KEY_PROG
	ZORG_SSH_KEY
	ZORG_USE_BORG_CACHE
	SOPS_PGP_FP
	SOPS_GPG_KEYSERVER
	SSH_AUTH_SOCK
)

decho () {
	[ -z "${ZORG_DEBUG:-}" ] && return 0
	echo >&2 "${@}"
}

dataset_exists () {
	 zfs list -H -p -o name -s name "${1}" &>/dev/null
}

sha256str () {
	str="${1}"
	sha256sum - <<< "${str}" | cut -d' ' -f1
}

creds_dir () {
	repo_name="${1}"
	old_dir="${scriptdir}/creds/${repo_name}"
	dir="${scriptdir}/creds/$(sha256str "${repo_name}")"
	if [ -d "${old_dir}" ] && ! [ -d "${dir}" ]; then
		mv -v "${old_dir}" "${dir}" 1>&2
	fi

	echo "${dir}"
}

write_file () {
	perms="${1}"
	target="${2}"

	>&2 mkdir -p "$(dirname -- "${target}")"
	>&2 touch "${target}"
	>&2 chmod 600 "${target}"
	cat > "${target}"
	>&2 chmod "${perms}" "${target}"
}


propagate_env () {
	envvars=()
	for var in "${propagated_envvars[@]}"; do
		value="${!var:-}"
		[ -z "${value}" ] && continue
		envvars+=("${var}=${value}")
	done

	echo env "${envvars[@]}" "${@}"
}

_determine_key_prog () {
	local credsdir="${1}"
	if [ -f "${credsdir}/type" ]; then
		echo "$(< "${credsdir}/type")"
	fi
}

encrypt_key () {
	local credsdir="${1}"
	local key_prog="${2:-}"
	if [ -z "${key_prog}" ]; then
		key_prog="$(_determine_key_prog "${credsdir}")"
	fi
	if [ -z "${key_prog}" ]; then
		key_prog="${default_key_prog}"
	fi
	if ! [ -x "${scriptdir}/key/${key_prog}" ]; then
		echo >&2 ">>> Unsupported key program '${key_prog}'"
		exit 1
	fi

	"${scriptdir}/key/${key_prog}" encrypt "${credsdir}"
	echo "${key_prog}" > "${credsdir}/type"
}

decrypt_key () {
	local credsdir="${1}"
	local key_prog; key_prog="$(_determine_key_prog "${credsdir}")"

	if ! [ -x "${scriptdir}/key/${key_prog}" ]; then
		echo >&2 ">>> Unsupported key program '${key_prog}'"
		exit 1
	fi

	"${scriptdir}/key/${key_prog}" decrypt "${credsdir}"
}

resolve_repo_dir () {
	local repodir="${1}"
	local repo_name="${2}"

	if [ -d "${repodir}/${repo_name}" ]; then
		echo -n "${repodir}/${repo_name}"
	elif [ -f "${repodir}/${repo_name}.remote" ]; then
		echo -n "$(< "${repodir}/${repo_name}.remote")"
	fi
}
