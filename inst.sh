#!/usr/bin/env bash
# Author: BlackBeans

MYSELF=${0##*/}

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
    echo " $MYSELF will replace every occurence of \`\!NAME\!'"
    echo ' with NAME.'
}

function fatal () {
    echo "$MYSELF: $*" >&2
    exit 1
}

ORIGIN=github:TheBlackBeans/templates

while [ $# -gt 2 ]
do
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
    esac
done

if [ $# -lt 1 ]; then
    fatal Missing argument TEMPLATE
elif [ $# -lt 2]; then
    fatal Missing argument NAME
fi

TEMPLATE=$1
NAME=$2

nix flake new -t ${ORIGIN}#$TEMPLATE $NAME
find $NAME -type f -not \( -name .svn -prune -o -name .git -prune \) -print0 | xargs -0 sed -i "s/\!NAME\!/$NAME/g"
