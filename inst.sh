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
	    fatal Unknown option $1
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
PATH=$2
NAME=${PATH##*/}

nix flake new -t ${ORIGIN}#$TEMPLATE $PATH || exit 1
find $PATH -type f -not \( -name .svn -prune -o -name .git -prune \) -print0 | xargs -0 sed -i "s/!NAME!/$NAME/g"
