#!/bin/bash
# creates or updates a brain-dead bash script to overload commands by their GNU
# coreutils versions

d=/usr/local/opt/coreutils/libexec/gnubin
l=$( dirname $( $d/realpath "${BASH_SOURCE[0]}" ) )/lib_coreutils.bash
u=""

if [ -e $l ]; then u="$( awk '!/^# /{printf $1}' $l )x"; fi

echo '#
# -*- mode: bash; tab-width: 4 -*-
################################################################################
#
# NAME
#   lib_coreutils.bash - source this to avoid having all coreutils in the PATH
#
# SYNOPSIS
#   source lib_coreutils.bash
#
# DESCRIPTION
#	This library replaces command calls by function calls to the coreutils in
#   '"$d"'
#
#   To recreate this library, run '"${0##*/}"'
#
# AUTHOR
#	@author     Andreas Tusche <antu-photo@andreas-tusche.de>
#	@copyright  (c) 2021-'$(date +"%Y")', Andreas Tusche <www.andreas-tusche.de>
#	@package    antu-photo
#
# when       who  what
# ---------- ---- --------------------------------------------------------------
# '$(date +"%Y-%m-%d")' auto created
' >$l

echo "(( \${coreutils_lib_loaded:-0} )) && return 0     # load me only once" >>$l
echo "((DEBUG)) && echo -n \"[ . \$BASH_SOURCE \"" >>$l
echo "" >>$l
echo "coreutils_DEVELOP=${coreutils_DEVELOP:-1}                              # special settings for while developing" >>$l
echo "coreutils_MY_VERSION='\$Revision: $(date +"%y.%m%d") \$'      # version of this library" >>$l
echo "" >>$l
echo "# uncomment those commands you need" >>$l

ls -1 $d | awk '
    {
        if (index("'$u'",$1)) { c="" } else { c="# " }
        printf "%-13s { %s } ; GNU_%s=\"%s\"\n", c $1 "()", "'$d'/" $1 " \"\$@\";", $1,  "'$d'/" $1
    }
' >>$l

echo "coreutils_lib_loaded=1; ((DEBUG)) && echo \"]\"" >>$l
echo "return 0" >>$l
