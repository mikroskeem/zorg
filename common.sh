# shellcheck shell=bash
# shellcheck disable=SC2034,SC2154 # parent scripts define this
: "${scriptdir}"

propagated_envvars=(
	PATH
	ZORG_DEBUG
	ZORG_SSH_KEY
	ZORG_USE_BORG_CACHE
)

decho () {
	[ -z "${ZORG_DEBUG:-}" ] && return 0
	echo "${@}"
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
		envvars+=("${var}=${!var:-}")
	done

	echo env "${envvars[@]}" "${@}"
}
