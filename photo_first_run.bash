#!/usr/bin/env bash
#
# check some prerquisits


#!#####################
echo "needs rewrite" #!
exit 1               #!
#!#####################


if [[ ${BASH_VERSINFO[0]} < 5 ]]; then
    echo "The version ${BASH_VERSINFO[0]} of bash is old. Please upgrade to version 5."
    echo "  brew install bash"
    echo "more information at https://itnext.io/upgrading-bash-on-macos-7138bd1066ba"
fi
