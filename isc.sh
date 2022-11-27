#!/usr/bin/env bash
# Author: jthulhu

MYSELF=isc
ORIGIN=github:jthulhu/templates
INSTINITFILE=inst-init.bash
TEMPLATES=~/.config/templates
CONFIG=~/.config/machines

function usage() {
    echo "$MYSELF -- install, setup and configure"
    echo 'Usage:'
    echo "  $MYSELF new [<options>] <template> <name> [<args>]"
    echo "  $MYSELF update [<options>]"
    echo "  $MYSELF <show|list> [<options>]"
    echo
    echo 'New options:'
    echo ' -h --help:               this message'
    echo ' -o --origin <origin>:    uri of the flake to fetch the template from'
    echo
    echo 'Additional arguments:'
    echo " Every additional argument will be forwarded to $INSTINITFILE, if found."
    echo ' Otherwise, no additional arguments are accepted.'
    echo
    echo 'Name replacement:'
    echo " $MYSELF will replace every occurence of \`!NAME!' with <name>, both in paths and"
    echo ' within files.'
}

function fatal() {
    echo "$MYSELF: $*" >&2
    exit 1
}

function rename_path() {
    file_path=$1
    name=$2
    # shellcheck disable=SC2016
    file_cmd='f=$(basename "$1")'
    # shellcheck disable=SC2016
    dir_cmd='d=$(dirname "$1")'
    # shellcheck disable=SC2016
    mv_cmd_first_part='mv "$1" "$d/${f//!NAME!/'
    mv_cmd_second_part='}"'
    command="${file_cmd}; ${dir_cmd}; ${mv_cmd_first_part}${name}${mv_cmd_second_part}"
    find "$file_path" -depth -name '*!NAME!*' -exec bash -c "$command" _ {} \;
}

function rename_content() {
    find "$1" -type f -not \( -name .svn -prune -o -name .git -prune \) \
	 -print0 | xargs -0 sed -i "s/!NAME!/$2/g"
}

function new_usage() {
    echo "MYSELF new -- setup a new flake environment"
}

function new() {
    while (($# > 0)); do
	case "$1" in
	    -h | --help )
		new_usage
		exit 0
		;;
	    -o | --origin )
		if [ $# -lt 2 ]; then
		    fatal 'Missing argument ORIGIN'
		fi
		ORIGIN=$2
		shift 2
		;;
	    -- )
		shift 1
		break
		;;
	    -* )
		fatal "Unknown option $1"
		;;
	    * )
		break
		;;
	esac
    done

    if (($# < 1)); then
	fatal 'Missing argument <template>'
    elif (($# < 2)); then
	fatal 'Missing argument <name>'
    fi

    template=$1
    file_path=$2
    name=${file_path##*/}

    shift 2

    nix flake new -t "${ORIGIN}"#"$template" "$file_path"
    rename_path "$file_path" "$name"
    rename_content "$file_path" "$name"
    cd "$file_path"
    if [ -f "$INSTINITFILE" ]; then
	echo "Running setup..."
	bash "$INSTINITFILE" "$@"
	echo "Done."
	rm "$INSTINITFILE"
    elif (($# > 0)); then
	echo "Warning: $INSTINITFILE wasn't found, and yet extra arguments were provided"
    fi
    if [ -f gitignore ]; then
	mv {,.}gitignore
    fi
    git init
    git add .
    git commit -m 'From scratch'
}

function update() {
    config=0
    templates=0
    pull=0
    while (($# > 0)); do
	case $1 in
	    -t | --templates )
		TEMPLATES="$2"
		shift 2
		break
		;;
	    -c | --config )
		CONFIG="$2"
		shift 2
		break
		;;
	    -p | --pull )
		pull=1
		shift
		break
		;;
	    -- )
		shift
		break
		;;
	    -* )
		fatal "Unknown option: $1"
		;;
	    config )
		config=1
		shift
		break
		;;
	    templates )
		templates=1
		shift
		break
		;;
	    * )
		fatal "Unknown positional argument: $1"
		;;
	esac
    done
    if (( templates == 1 )); then
	pushd "$TEMPLATES"
	nix flake update
	for template in *; do
	    pushd "$template"
	    nix flake update
	    popd
	done
	if (( pull == 0 )); then
	    git pull
	fi
	popd
    fi
    if (( config == 1 )); then
	pushd "$CONFIG"
	nix flake update
	if (( pull == 0 )); then
	    git pull
	fi
	popd
    fi
}

function list () {
    nix flake show --json "$TEMPLATES" | jq -r '.template | keys[]'
}

if (($# < 1)); then
    usage
    exit 1
fi

case "$1" in
    new )
	shift
	new "$@"
	break
	;;
    update )
	shift
	update "$@"
	break
	;;
    show | list )
	shift
	list "$@"
	break
	;;
    -h | --help )
	shift
	usage
	exit 0
	;;
    -- )
	shift
	break
	;;
    -* )
	fatal "Unknown argument: '$1'"
	;;
    * )
	fatal "Unknown positional argument: '$1'"
	;;
esac
