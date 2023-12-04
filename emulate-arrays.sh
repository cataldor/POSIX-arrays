#!/bin/sh

# emulate-arrays.sh

# emulates arrays in POSIX shell

# each array element is stored in a variable named in the format '___emu_[x]_[arr_name]_[key/index]'
# where [x] is either 'a' for associative array or 'i' for indexed array

# keys/indices are stored in a variable named in the format '___emu_[x]_[arr_name]_keys' or '___emu_[x]_[arr_name]_indices'


# declare an emulated indexed array while populating first elements
# 1 - array name
# all other args - array values
declare_i_arr() {
	[ $# -lt 1 ] && { echo "declare_i_arr: Error: not enough arguments." >&2; return 1; }
	___arr_name="$1"; shift
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "declare_i_arr: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	___indices=""

	clean_i_arr "$___arr_name"
	___index=0
	if [ -n "$*" ]; then
		for ___val in "$@"; do
			eval "___emu_i_${___arr_name}_${___index}=\"$___val\""
			___indices="$___indices$___index$___newline"
			___index=$((___index + 1))
		done
	fi

	eval "___emu_i_${___arr_name}_high_index=\"$((___index - 1))\""
	eval "___emu_i_${___arr_name}_indices=\"$___indices\""

	unset ___val ___index ___indices
	return 0
}

# read lines from input string or from a file into an indexed array
# array is reset if already exists
# 1 - array name
# 2, 3 - [-f filename] - input file to read from
# 2 - if no file specified, newline-separated string
# no additional arguments are allowed
read_i_arr() {

	___arr_name="$1"; shift
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "read_i_arr: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	while getopts ":f:" opt; do
		case $opt in
			f) ___input_file=$OPTARG;;
			\?) echo "read_i_arr: Error: Unknown option: '$OPTARG'."; return 1
		esac
	done
	shift $((OPTIND - 1))

	if [ -n "$___input_file" ]; then
		[ -n "$*" ] && { echo "read_i_arr: Error: invalid arguments '$*'."; return 1; }
		___lines="$(cat "$___input_file")" || \
			{ echo "read_i_arr: Error: failed to read file '$___input_file'."; return 1; }
	else
		___lines="$1"; shift
		[ -n "$*" ] && { echo "read_i_arr: Error: invalid arguments '$*'."; return 1; }
	fi
	[ -z "$___lines" ] && { echo "read_i_arr: Error: received an empty string."; return 1; }

	clean_i_arr "$___arr_name"

	___indices=""
	___index=0
    IFS_OLD="$IFS"
    IFS="$___newline"
	for ___line in $___lines; do
		eval "___emu_i_${___arr_name}_${___index}=\"$___line\""
		___indices="$___indices$___index$___newline"
		___index=$((___index + 1))
	done
    IFS="$IFS_OLD"

	eval "___emu_i_${___arr_name}_high_index=\"$((___index - 1))\""
	eval "___emu_i_${___arr_name}_indices=\"$___indices\""

	unset ___line ___lines ___index ___indices ___input_file
	return 0
}

clean_i_arr() {
	[ $# -ne 1 ] && { echo "clean_i_arr: Error: wrong number of arguments." >&2; return 1; }
	___arr_name="$1"
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "clean_i_arr: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	___indices="$(eval "printf '%s' \"\$___emu_i_${___arr_name}_indices\"" | sort -u)"

	for ___index in $___indices; do
		unset "___emu_i_${___arr_name}_${___index}"
	done
	unset "___emu_i_${___arr_name}_indices"
	unset ___indices ___index "___emu_i_${___arr_name}_high_index"
}

# get all values from an emulated indexed array (sorted by index)
# 1 - array name
# no additional arguments are allowed
get_i_arr_values() {
	[ $# -ne 1 ] && { echo "get_i_arr_all: Error: wrong number of arguments." >&2; return 1; }
	___arr_name="$1"
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "get_i_arr_all: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	___indices="$(eval "printf '%s' \"\$___emu_i_${___arr_name}_indices\"" | sort -nu)"
	for ___index in $___indices; do
		eval "___val=\"\$___emu_i_${___arr_name}_${___index}\""
		[ -n "$___val" ] && printf '%s\n' "$___val" 
	done

	eval "___emu_i_${___arr_name}_indices=\"$___indices\""

	unset ___all_values ___indices ___index ___val
	return 0
}

# get all indices from an emulated indexed array (sorted)
# 1 - array name
# no additional arguments are allowed
get_i_arr_indices() {
	[ $# -ne 1 ] && { echo "get_i_arr_all_indices: Error: wrong number of arguments." >&2; return 1; }
	___arr_name="$1"
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "get_i_arr_all_indices: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	___indices="$(eval "printf '%s' \"\$___emu_i_${___arr_name}_indices\"" | sort -nu)"
	___indices="$(
		for ___index in $___indices; do
			eval "___val=\"\$___emu_i_${___arr_name}_${___index}\""
			[ -n "$___val" ] && printf '%s\n' "$___index"
		done
	)"
	eval "___emu_i_${___arr_name}_indices=\"$___indices\""
	printf '%s' "$___indices"

	unset ___indices ___index
	return 0
}

# add a new element to an indexed array and set its value
# 1 - array name
# 2 - value
# no additional arguments are allowed
add_i_arr_el() {
	___arr_name="$1"; ___new_val="$2"; ___verified_indices=""
	if [ $# -ne 2 ]; then echo "add_i_arr_el: Error: Wrong number of arguments." >&2; return 1; fi
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "add_i_arr_el: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	eval "___high_index=\"\$___emu_i_${___arr_name}_high_index\""

	if [ -z "$___high_index" ]; then
		___indices="$(eval "printf '%s' \"\$___emu_i_${___arr_name}_indices\"" | sort -nu)"
		___high_index="-1"

		for ___index in $___indices; do
			eval "___val=\"\$___emu_i_${___arr_name}_${___index}\""
			if [ -n "$___val" ]; then
				___verified_indices="${___verified_indices}$___index$___newline"
				[ "$___index" -gt "$___high_index" ] && ___high_index="$___index"
			fi
		done
		___index=$((___high_index + 1))
		eval "___emu_i_${___arr_name}_indices=\"${___verified_indices}${___index}${___newline}\""
	else
		___index=$((___high_index + 1))
		eval "___emu_i_${___arr_name}_indices=\"\$___emu_i_${___arr_name}_indices\"\"${___index}${___newline}\""
	fi

	eval "___emu_i_${___arr_name}_high_index=\"$___index\""
	eval "___emu_i_${___arr_name}_${___index}=\"$___new_val\""

	unset ___new_val ___val ___indices ___index ___high_index ___verified_indices
	return 0
}

# set a value in an emulated indexed sparse array
# 1 - array name
# 2 - index
# 3 - value (if no value, unsets the index)
# no additional arguments are allowed
set_i_arr_el() {
	___arr_name="$1"; ___index="$2"; ___new_val="$3"
	if [ $# -lt 2 ] || [ $# -gt 3 ]; then echo "set_i_arr_el: Error: Wrong number of arguments." >&2; return 1; fi
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "set_i_arr_el: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	case "$___index" in *[!0-9]*) echo "set_i_arr_el: Error: '$___index' is not a nonnegative integer." >&2; return 1 ; esac

	eval "___old_val=\"\$___emu_i_${___arr_name}_${___index}\""

	if [ -z "$___old_val" ] && [ -n "$___new_val" ]; then
		eval "___emu_i_${___arr_name}_indices=\"\${___emu_i_${___arr_name}_indices}${___index}${___newline}\""
	fi

	unset "___emu_i_${___arr_name}_high_index"
	eval "___emu_i_${___arr_name}_${___index}=\"$___new_val\""

	unset ___index ___new_val ___old_val
	return 0
}

# get a value from an emulated indexed array
# 1 - array name
# 2 - index
# no additional arguments are allowed
get_i_arr_el() {
	if [ $# -ne 2 ]; then echo "get_i_arr_el: Error: Wrong number of arguments." >&2; return 1; fi
	___arr_name="$1"; ___index="$2"
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "get_i_arr_el: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	case "$___index" in *[!0-9]*) echo "get_i_arr_el: Error: no index specified or '$___index' is not a nonnegative integer." >&2; return 1; esac
	eval "printf '%s\n' \"\$___emu_i_${___arr_name}_${___index}\""
	unset ___index
}




# declare an emulated associative array while populating elements
# 1 - array name
# all other args - 'key=value' pairs
declare_a_arr() {
	[ $# -lt 1 ] && { echo "declare_a_arr: Error: not enough arguments." >&2; return 1; }
	___arr_name="$1"; shift
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "declare_a_arr: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	___keys=""

	clean_a_arr "$___arr_name"
	if [ -n "$*" ]; then
		for ___pair in "$@"; do
			case "$___pair" in *=*) ;; *) echo "declare_a_arr: Error: '$___pair' is not a 'key=value' pair." >&2; return 1 ;; esac
			___key="${___pair%%=*}"
			___val="${___pair#*=}"
			case "$___key" in *[!A-Za-z0-9_]*) echo "declare_a_arr: Error: invalid key '$___key'." >&2; return 1; esac
			eval "___emu_a_${___arr_name}_${___key}=\"$___val\""
			eval "_${___arr_name}_${___key}_=1"
			___keys="$___keys$___key$___newline"
		done
	fi

	eval "___emu_a_${___arr_name}_keys=\"$___keys\""

	unset ___val ___key ___keys
	return 0
}

# get all values from an emulated associative array (alphabetically sorted by key)
# 1 - array name
# no additional arguments are allowed
get_a_arr_values() {
	[ $# -ne 1 ] && { echo "get_a_arr_all: Error: wrong number of arguments." >&2; return 1; }
	___arr_name="$1"
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "get_a_arr_all: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	___keys="$(eval "printf '%s' \"\$___emu_a_${___arr_name}_keys\"" | sort -u)"
	for ___key in $___keys; do
		eval "___val=\"\$___emu_a_${___arr_name}_${___key}\""
		[ -n "$___val" ] && printf '%s\n' "${___val#"${___delim}"}"
	done

	eval "___emu_a_${___arr_name}_keys=\"$___keys\""
	unset ___keys ___key ___val
	return 0
}

# get all keys from an emulated associative array (alphabetically sorted)
# 1 - array name
# no additional arguments are allowed
get_a_arr_keys() {
	[ $# -ne 1 ] && { echo "get_a_arr_all_keys: Error: wrong number of arguments." >&2; return 1; }
	___arr_name="$1"
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "get_a_arr_all_keys: Error: invalid array name '$___arr_name'." >&2; return 1; esac

	___keys="$(eval "printf '%s' \"\$___emu_a_${___arr_name}_keys\"" | sort -u)"
	___keys="$(
		for ___key in $___keys; do
			eval "___old_val=\"\$___emu_a_${___arr_name}_${___key}\""
			[ -n "$___old_val" ] && printf '%s\n' "$___key"
		done
	)"

	eval "___emu_a_${___arr_name}_keys=\"$___keys\""
	printf '%s' "$___keys"

	unset ___keys ___key ___old_val
	return 0
}

# set a value in an emulated associative array
# 1 - array name
# 2 - key
# 3 - value (if no value, sets an empty string)
# no additional arguments are allowed
set_a_arr_el() {
	___arr_name="$1"; ___pair="$2"
	if [ $# -ne 2 ]; then echo "set_a_arr_el: Error: Wrong number of arguments." >&2; return 1; fi
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "set_a_arr_el: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	case "$___pair" in *=*) ;; *) echo "set_a_arr_el: Error: '$___pair' is not a 'key=value' pair." >&2; return 1 ;; esac
	___key="${___pair%%=*}"
	___new_val="${___pair#*=}"
	case "$___key" in *[!A-Za-z0-9_]*) echo "set_a_arr_el: Error: invalid key '$___key'." >&2; return 1; esac

	eval "___old_val=\"\$___emu_a_${___arr_name}_${___key}\""

	if [ -z "$___old_val" ] && [ -n "$___key" ]; then
		eval "___emu_a_${___arr_name}_keys=\"\${___emu_a_${___arr_name}_keys}${___key}${___newline}\""
	fi

	eval "___emu_a_${___arr_name}_${___key}=\"${___delim}${___new_val}\""

	unset ___key ___new_val ___old_val
	return 0
}

# get a value from an emulated associative array
# 1 - array name
# 2 - key
# no additional arguments are allowed
get_a_arr_el() {
	if [ $# -ne 2 ]; then echo "get_a_arr_el: Error: Wrong number of arguments." >&2; return 1; fi
	___arr_name="$1"; ___key=$2
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "get_a_arr_el: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	case "$___key" in *[!A-Za-z0-9_]*) echo "get_a_arr_el: Error: invalid key '$___key'." >&2; return 1; esac

	eval "___val=\"\$___emu_a_${___arr_name}_${___key}\""
	printf '%s\n' "${___val#"${___delim}"}"
	unset ___key
}

clean_a_arr() {
	[ $# -ne 1 ] && { echo "clean_a_arr: Error: wrong number of arguments." >&2; return 1; }
	___arr_name="$1"
	case "$___arr_name" in *[!A-Za-z0-9_]*) echo "clean_a_arr: Error: invalid array name '$___arr_name'." >&2; return 1; esac
	eval "___keys=\"\$___emu_a_${___arr_name}_keys\""

	for ___key in $___keys; do
		unset "___emu_a_${___arr_name}_${___key}"
	done
	unset "___emu_a_${___arr_name}_keys"
	unset ___keys ___key
}


___newline="
"
___delim="$(printf '\35')"