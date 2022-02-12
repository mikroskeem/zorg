decho () {
	[ -z "${ZORG_DEBUG:-}" ] && return 0
	echo "${@}"
}

dataset_exists () {
	 zfs list -H -p -o name -s name "${1}" &>/dev/null
}
