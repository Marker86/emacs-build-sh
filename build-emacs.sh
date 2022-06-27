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

# Le option parsing.
while getopts :ghv OPT; do
    case $OPT in
        c|+c)
            CLEAR=1 # Clear before configuring.
            ;;
        g|+g)
            GIT_PULL=1 # Pull from git.
            ;;
        h|+h)
            # Forgive me for this.
            echo -e "${0##*/} usage:"
            echo -e "\t[-+]h: Prints this message."
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
if [ -d "${EMACS_SRC}" ]
then
    cd ${EMACS_SRC}
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
make -j${JOBS:-$(nproc)} ${TARGET:-""}
