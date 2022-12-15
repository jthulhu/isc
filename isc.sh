#!/usr/bin/env bash
# Author: jthulhu

MYSELF=isc
ORIGIN=github:jthulhu/templates
INSTINITFILE=inst-init.bash
TEMPLATES_DIR=~/.config/templates
CONFIG_DIR=~/.config/machines

function usage() {
    echo "$MYSELF -- install, setup and configure"
    echo
    echo 'Usage:'
    echo "  $MYSELF new [-o <origin>] <template> <name> [<args>]    instantiate new project"
    echo "  $MYSELF update [<options>]                              update system"
    echo "  $MYSELF list                                     show available templates"
    echo "  $MYSELF --help                                          show this message"
}

function new_usage() {
    echo "$MYSELF new -- setup a new flake environment"
    echo
    echo 'Usage:'
    echo "  $MYSELF new [-o <origin>] <template> <name> [<args>]"
    echo
    echo 'Options:'
    echo '  -o --origin <origin>     uri of the flake to fetch the template from'
    echo
    echo 'Additional arguments:'
    echo "  Every additional argument will be forwarded to $INSTINITFILE, if found."
    echo '  Otherwise, no additional arguments are accepted.'
    echo
    echo 'Name replacement:'
    # shellcheck disable=SC2016
    echo "  $MYSELF"' will replace every occurence of `!NAME!` with <name>, both in paths and'
    echo '  within files.'
}

function update_usage() {
    echo "$MYSELF update -- update the system"
    echo
    echo 'Usage:'
    echo "  $MYSELF update [<options>] <command>"
    echo
    echo 'Options:'
    echo '  -p --push              automatically push every update'
    echo '  -c --config            the configuration directory'
    echo '  -t --templates         the templates directory'
    echo
    echo 'Command:'
    echo '  config                 update the configuration'
    echo '  templates              update the templates'
    echo '  all                    update everything'
}

function list_usage() {
    echo "$MYSELF list -- list the available templates"
    echo
    echo 'Usage:'
    echo "  $MYSELF list"
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

function new() {
    while (($# > 0)); do
	case "$1" in
	    -o | --origin )
		if [ $# -lt 2 ]; then
		    fatal 'Missing argument ORIGIN'
		fi
		ORIGIN=$2
		shift 2
		;;
	    -h | --help )
		new_usage
		exit 0
		;;
	    -- )
		shift 1
		;;
	    -* )
		fatal "Unknown option $1"
		;;
	    * )
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
    push=0
    while (($# > 0)); do
	case $1 in
	    -t | --templates )
		TEMPLATES_DIR="$2"
		shift 2
		;;
	    -c | --config )
		CONFIG_DIR="$2"
		shift 2
		;;
	    -p | --push )
		push=1
		shift
		;;
	    -h | --help )
		update_usage
		exit 0
		;;
	    -- )
		shift
		;;
	    -* )
		fatal "Unknown option: '$1'"
		;;
	    config )
		config=1
		shift
		;;
	    templates )
		templates=1
		shift
		;;
	    all )
		templates=1
		config=1
		shift
		;;
	    * )
		fatal "Unknown positional argument: '$1'"
		;;
	esac
    done
    if (( templates == 1 )); then
	pushd "$TEMPLATES_DIR"
	nix flake update
	for template in */; do
	    pushd "$template"
	    nix flake update
	    popd
	done
	if (( push == 0 )); then
	    git push
	fi
	popd
    fi
    if (( config == 1 )); then
	pushd "$CONFIG_DIR"
	nix flake update
	if (( push == 0 )); then
	    git push
	fi
	popd
    fi
}

function list() {
    while (($# > 0)); do
	case $1 in
	    -h | --help )
		list_usage
		exit 0
		;;
	    -* )
		fatal "Unknown argument: '$1'"
		;;
	    * )
		fatal "Unknown positional argument: '$1'"
		;;
	esac
    done
    echo 'The available templates are the following.'
    nix flake show --json "$ORIGIN" \
	| jq -r '.templates | to_entries[] | " - " + .key + ": " + .value.description'
}

if (($# < 1)); then
    usage
    exit 1
fi

case "$1" in
    new )
	shift
	new "$@"
	;;
    update )
	shift
	update "$@"
	;;
    show | list )
	shift
	list "$@"
	;;
    -h | --help )
	shift
	usage
	exit 0
	;;
    -* )
	fatal "Unknown argument: '$1'"
	;;
    * )
	fatal "Unknown positional argument: '$1'"
	;;
esac
