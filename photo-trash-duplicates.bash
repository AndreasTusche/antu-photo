#!/usr/bin/env bash
# -*- mode: bash; tab-width: 4 -*-
################################################################################
# NAME
#	
# SYNOPSIS	
#
# DESCRIPTION
#
# FILES
#
# AUTHOR
#	@author     Andreas Tusche    <antu-photo@andreas-tusche.de>
#	@copyright  (c) 2021, Andreas Tusche <www.andreas-tusche.de>
#	@package    antu-photo
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# when       who  what
# ---------- ---- --------------------------------------------------------------
# 2018-12-29 AnTu created
# 2021-01-23 AnTu use fdupes


#!#####################
echo "needs rewrite" #!
exit 1               #!
#!#####################


################################################################################
# config
################################################################################

#-------------------------------------------------------------------------------
# Global shell behaviour
#-------------------------------------------------------------------------------

DEBUG=${DEBUG:-0}						# 0: do not 1: do print debug messages
                                        # 2: bash verbose, 3: bash xtrace
										# 9: bash noexec

set -o nounset                          # Used variables MUST be initialized.
set -o errtrace                         # Traces error in function & co.
set -o functrace                        # Traps inherited by functions
set -o pipefail                         # Exit on errors in pipe
set +o posix                            # disable POSIX

((DEBUG>1)) && set -o verbose; ((DEBUG<2)) && set +o verbose
((DEBUG>2)) && set -o xtrace;  ((DEBUG<3)) && set +o xtrace
((DEBUG>8)) && set -o noexec;  ((DEBUG<9)) && set +o noexec

((DEBUG)) && VERBOSE=1 || VERBOSE=${VERBOSE:-$DEBUG}
((DEBUG)) && clear && banner -w 32 $(date +%T)

# preliminary functions, may be replaced by those from lib_common.bash
die()        { err=${1-1}; shift; [ -z ${1+x} ] || printError "$@"; exit $err ; }
printDebug() { ((DEBUG)) && echo -e "$(date +'%F %T') \033[1;35mDEBUG  :\033[0;35m ${@}\033[0m" ; }
printError() {              echo -e "$(date +'%F %T') \033[1;91mERROR  :\033[0;91m ${@}\033[0m" ; }
if ! command -v realpath &>/dev/null ; then realpath() { readlink -- "$1" ; } ; fi

#-------------------------------------------------------------------------------
# path to this script - needs GNU `realpath` installed
#-------------------------------------------------------------------------------

readonly _THIS_SCRIPT="$( realpath "${BASH_SOURCE[0]}" )"
readonly _THIS=$( basename "$_THIS_SCRIPT" )
readonly _THIS_DIR="$( dirname $_THIS_SCRIPT )"

printDebug "_THIS_SCRIPT  = $_THIS_SCRIPT"
printDebug "_THIS         = $_THIS"
printDebug "_THIS_DIR     = $_THIS_DIR"



#-------------------------------------------------------------------------------
# load some function libraries
#-------------------------------------------------------------------------------

source "$_THIS_DIR/lib_common.bash" && ((common_lib_loaded)) || die 53 "Library lib_common.bash was not found."
source "$_THIS_DIR/lib_photo.bash"  && ((photo_lib_loaded))  || die 53 "Library lib_photo.bash was not found."



#-------------------------------------------------------------------------------
# config
#-------------------------------------------------------------------------------

LOGFILE=photo_trash_duplicates.log
rotateLog $LOGFILE



################################################################################
# MAIN
################################################################################

printToLog '-------------------------------------------------------------------'
printToLog "$_THIS started"

# @Todo: allow multiple directories
photo_trash_duplicates "${1:-$(pwd)}"
