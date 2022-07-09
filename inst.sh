#!/usr/bin/env bash
# Author: BlackBeans

MYSELF=inst

function usage () {
    echo "$MYSELF -- setup a new flake environment"
    echo "Usage: $MYSELF [OPTIONS] TEMPLATE NAME"
    echo
    echo 'Options:'
    echo ' -h --help:             this message'
    echo ' -o --origin ORIGIN:    uri of the flake to fetch'
    echo '                        the template from'
    echo
    echo 'Name replacement:'
    echo " $MYSELF will replace every occurence of \`!NAME!'"
    echo ' with NAME.'
}

function fatal () {
    echo "$MYSELF: $*" >&2
    exit 1
}

function rename_path () {
    # shellcheck disable=SC2016
    file_cmd='f=$(basename "$1")'
    # shellcheck disable=SC2016
    dir_cmd='d=$(dirname "$1")'
    # shellcheck disable=SC2016
    mv_cmd_first_part='mv "$1" "$d/${f//!NAME!/'
    mv_cmd_second_part='}"'
    command="${file_cmd}; ${dir_cmd}; ${mv_cmd_first_part}$NAME${mv_cmd_second_part}"
    find "$FILE_PATH" -depth -name '*!NAME!*' -exec bash -c "$command" _ {} \;
}

function rename_content () {
    find "$FILE_PATH" -type f -not \( -name .svn -prune -o -name .git -prune \) -print0 | xargs -0 sed -i "s/!NAME!/$NAME/g"
}

ORIGIN=github:TheBlackBeans/templates

while (($# > 0)); do
    case "$1" in
	-h | --help )
	    usage
	    exit 0
	    ;;
	-o | --origin )
	    if [ $# -lt 2 ]; then
		fatal Missing argument ORIGIN
	    fi
	    ORIGIN=$2
	    shift 2
	    ;;
	-* )
	    fatal Unknown option "$1"
	    ;;
	* )
	    break
    esac
done

if (($# < 1)); then
    fatal Missing argument TEMPLATE
elif (($# < 2)); then
    fatal Missing argument NAME
elif (($# > 2)); then
    fatal Too many arguments
fi

TEMPLATE=$1
FILE_PATH=$2
NAME=${FILE_PATH##*/}

nix flake new -t "${ORIGIN}"#"$TEMPLATE" "$FILE_PATH"
rename_path
rename_content
