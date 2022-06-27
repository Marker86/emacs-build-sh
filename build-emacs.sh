#!/usr/bin/bash

# Predefine some configuration flags.
declare CONF_FLAGS="--with-native-compilation --with-wide-int"

# Catch errors.
set -e

# Handy function.
function is_set()
{
    # $1 MUST be a string.
    if [ -z "${1}" ]
    then
        echo "${0##*/}: is_set: variable name passed is nil!"
        return 2
    fi

    # Check the variable is set, or has a value, same thing really.
    if [ -n "${!1}" ]
    then
        return 0
    else
        return 1
    fi
}

function echo_set()
{
    # $1 MUST be a string too.
    if [ -z "${1}" ]
    then
        echo "${0##*/}: is_echo: variable name passed is nil!"
        return 2
    fi

    declare status=$(is_set "${1}")
    if [ -n ${status} ]
    then
        echo "${1} is defined."
    else
        echo "${1} is empty.${2:-''}"
    fi
}

# Le option parsing.
while getopts :cgphv OPT; do
    case $OPT in
        c|+c)
            CLEAR=1 # Clear before configuring.
            ;;
        g|+g)
            GIT_PULL=1 # Pull from git.
            ;;
        p|+p)
            EMACS_DIST=1 # Package EMACS.
            ;;
        h|+h)
            # Forgive me for this.
            echo -e "${0##*/} usage:"
            echo -e "\t[-+]h: Prints this message."
            echo -e "\t[-+]p: Package EMACS after build."
            echo -e "\t[-+]v: Prints the version of this script."
            echo -e "\t[-+]g: Pull a fresher version of the repository, if the source is from"
            echo -e "\t       a repository."
            echo -e "\t[-+]c: Clear the build folder before continuing."
            exit 0
            ;;
        v|+v)
            echo -e "${0##*/} version 0.2"
            exit 0
            ;;
        *)
            echo "usage: ${0##*/} [+-ghv] [--] ARGS..."
            exit 2
    esac
done
shift $(( OPTIND - 1 ))
OPTIND=1

# Set the path so it doesn't conflicts with my ada GNAT community edition installation
# so it should be wiped then set again.
PATH=""
for path in {,/usr}{/bin,/sbin}
do
    PATH="${path}:${PATH}"
done

# Get rid of the last ":" for prettiness (no one will see the variable beyond bash
# either way).
PATH=${PATH%":"}

# now cd to the place specified by EMACS_SRC, or to "emacs" if EMACS_SRC is nil.
if [ -d "${EMACS}" ]
then
    cd ${EMACS}
elif [ -d "emacs" ]
then
     cd "emacs"
else
    # Display an error if it isn't possible to locate the "emacs" source folder.
    echo "${0##*/}: error, 'emacs' source folder not found, quitting."
    exit 1
fi

# Pull from git if it is found (if one is using this option, it should be a guarantee)
# but first check the value itself is set.
declare status=$(is_set "GIT_PULL")
if [[ ${status} -eq 0 ]]
then
    git pull || echo "${0##*/}: git process returned a non-zero status code."
fi
unset -v status # Being precautious.

# Make clear, if a makefile is found.
declare status=$(is_set "CLEAR")
if [[ ${status} -eq 0 && -f "Makefile" ]]
then
    make clean
fi
unset -v status

# Then configure with the specified flags.
if [ -f "configure" ]; then
    ./configure ${CONF_FLAGS:-""}
else
    ./autogen.sh
    ./configure ${CONF_FLAGS:-""}
fi

# Then make, TARGET shall be used if it is defined, the same for JOBS.
make -j${JOBS:-$(nproc)} ${TARGET}

# If -p is set, package the EMACS, by default will package it inside a tar
# file.
declare status=$(is_set "EMACS_DIST")
if [[ ${status} -eq 0]]
then
    EMACS=${EMACS:-${PWD}}
    ./make-dist ${DIST_FLAGS:-"--tar"}
fi
