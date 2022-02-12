# shellcheck shell=bash
# shellcheck disable=SC2034,SC2154 # parent scripts define this
: "${scriptdir}"

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
