#!/bin/bash
# -*- mode: bash; tab-width: 4 -*-
################################################################################
#
# NAME
#   make_lib_coreutils.bash - (re-)create the lib_coreutils.bash library.
#
# SYNOPSIS
#   make_lib_coreutils.bash
#
# DESCRIPTION
#   Creates or updates a brain-dead bash script to overload commands by their GNU
#   coreutils versions.
#
# AUTHOR
#	@author     Andreas Tusche <bash_libraries@andreas-tusche.de>
#	@copyright  (c) 2021-2023, Andreas Tusche <www.andreas-tusche.de>
#	@package    antu::bash_libraries
#	@version    $Revision: 2.0.2 $
#	@(#) $Id: lib_common.sh,v 2.0.2 2023/04/10 AnTu Exp $
#
# when       who  what
# ---------- ---- --------------------------------------------------------------
# 2021-04-01 AnTu created
# 2023-04-10 AnTu Have version of the corutils in revision number

d=/usr/local/opt/coreutils/libexec/gnubin
l=$( dirname $( $d/realpath "${BASH_SOURCE[0]}" ) )/lib_coreutils.bash
u=""
v=$( $d/ls --version | awk '/^ls \(GNU/ {print $4}' )

if [ -e $l ]; then u="$( awk '!/^# /{printf $1}' $l )x"; fi

echo '#
# -*- mode: bash; tab-width: 4 -*-
################################################################################
#
# NAME
#   lib_coreutils.bash - source this when you do not want coreutils in the PATH
#
# SYNOPSIS
#   source lib_coreutils.bash
#
# DESCRIPTION
#	This library replaces some command calls by function calls to the coreutils
#   version '$v' in '"$d"'
#
#   To recreate this library, run '"${0##*/}"'
#
# AUTHOR
#	@author     Andreas Tusche <bash_libraries@andreas-tusche.de>
#	@copyright  (c) 2021-'$(date +"%Y")', Andreas Tusche <www.andreas-tusche.de>
#	@package    antu::bash_libraries
#	@version    $Revision: '$(date +"%y.")$v' $
#	@(#) $Id: lib_common.sh,v '$(date +"%y.")$v$(date +" %Y/%m/%d")' AnTu Exp $
#
# when       who  what
# ---------- ---- --------------------------------------------------------------
# '$(date +"%Y-%m-%d")' auto created
' >$l

echo "(( \${coreutils_lib_loaded:-0} )) && return 0     # load me only once" >>$l
echo "((DEBUG)) && echo -n \"[ . \$BASH_SOURCE \"" >>$l
echo "" >>$l
echo "coreutils_DEVELOP=${coreutils_DEVELOP:-1}                              # special settings for while developing" >>$l
echo "coreutils_MY_VERSION='\$Revision: $(date +"%y.")$v \$'       # version of this library" >>$l
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
