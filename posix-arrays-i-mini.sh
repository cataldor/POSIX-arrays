#!/bin/sh
# shellcheck disable=SC2154,SC2086

# Copyright: friendly bits
# github.com/friendly-bits

# posix-arrays-i-mini.sh

# emulates indexed arrays in POSIX shell

# NOTE: this is a stripped down to a minimum and optimized for very small arrays version,
# which includes a minimal subset of functions from the main project:
# https://github.com/friendly-bits/POSIX-arrays


# 1 - array name
# 2 - var name for output
get_i_arr_indices() {
	___me="get_i_arr_indices"
	case $# in 2) ;; *) wrongargs "$@"; return 1; esac
	_arr_name="$1" _out_var="$2"
	_check_vars _arr_name _out_var || return 1

	eval "_indices=\"\${_i_${_arr_name}_indices:-}\""

	_indices="$(printf '%s ' $_indices)" # no quotes on purpose

	eval "$_out_var"='${_indices% }'

	:
}

# 1 - array name
# 2 - index
# 3 - value
set_i_arr_el() {
	___me="set_i_arr_el"
	case $# in 2|3) ;; *) wrongargs "$@"; return 1; esac
	_arr_name="$1"; _index="$2"; ___new_val="${3:-}"
	_check_vars _arr_name && check_index || return 1

	eval "_indices=\"\${_i_${_arr_name}_indices:-}\"
			_i_${_arr_name}_${_index}"='${___new_val}'

	case "$_indices" in
		*"$_nl$_index"|*"$_nl$_index$_nl"* ) ;;
		*) eval "_i_${_arr_name}_indices=\"$_indices$_nl$_index\""
	esac
	:
}

# 1 - array name
# 2 - index
# 3 - var name for output
get_i_arr_val() {
	___me="get_i_arr_val"
	case $# in 3) ;; *) wrongargs "$@"; return 1; esac
	_arr_name="$1"; _index="$2"; _out_var="$3"
	_check_vars _arr_name _out_var && check_index || return 1

	eval "$_out_var=\"\$_i_${_arr_name}_${_index}\""
}


## Backend functions

_check_vars() {
	case "${nocheckvars:-}" in *?*) return 0; esac
	for ___var in "$@"; do
		eval "_var_val=\"\$$___var\""
		case "$_var_val" in ''|*[!A-Za-z0-9_]* )
			case "$___var" in
				_arr_name) _var_desc="array name" ;;
				_out_var) _var_desc="output variable name"
			esac
			printf '%s\n' "$___me: Error: invalid $_var_desc '$_var_val'." >&2
			return 1
		esac
	done
}

check_index() {	case "$_index" in ''|*[!0-9]* ) echo "$___me: Error: index '$_index' is not a nonnegative integer." >&2; return 1; esac; }
wrongargs() { echo "$___me: Error: '$*': wrong number of arguments '$#'." >&2; }

set -f
export LC_ALL=C
_nl='
'
