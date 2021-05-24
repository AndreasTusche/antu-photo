#!/bin/bash
# -*- mode: bash; tab-width: 4 -*-
################################################################################
#
# NAME
#   photo-rename-fntime.bash - set filename to time found in filename
#
# USAGE
#   photo-rename-fntime.bash [FILENAME|DIRNAME]
#
# DESCRIPTION
#   Digits found in the filename are interpreted as date and time. If that time
#	is between the beginning of photography (1815) and the end of the current
#	year, then the file will be renamed in place to yymmdd-HHMMSS.ext.
#	The Exif header of the file will not be modified.
#
#	Files are searched recursively in all subdirectories.
#
# AUTHOR
#	@author     Andreas Tusche    <antu-photo@andreas-tusche.de>
#	@copyright  (c) 2021-2021, Andreas Tusche <www.andreas-tusche.de>
#	@package    antu-photo
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# when       who  what
# ---------- ---- --------------------------------------------------------------
# 2021-05-19 AnTu created

################################################################################
# config
################################################################################

#-------------------------------------------------------------------------------
# Global shell behaviour
#-------------------------------------------------------------------------------

DEBUG=${DEBUG-''}						# 0: do not 1: do print debug messages
                                        # 2: bash verbose, 3: bash xtrace
										# 9: bash noexec

set -o nounset                          # Used variables MUST be initialized.
set -o errtrace                         # Traces error in function & co.
set -o functrace                        # Traps inherited by functions
set -o pipefail                         # Exit on errors in pipe
set +o posix                            # disable POSIX

((DEBUG==0)) && DEBUG=
((DEBUG>1)) && set -o verbose; ((DEBUG<2)) && set +o verbose
((DEBUG>2)) && set -o xtrace;  ((DEBUG<3)) && set +o xtrace
((DEBUG>8)) && set -o noexec;  ((DEBUG<9)) && set +o noexec

((DEBUG)) && VERBOSE=1 || VERBOSE=${VERBOSE:-$DEBUG}
((DEBUG)) && clear && banner -w 32 $(date +%T)

# preliminary functions, may be replaced by those from lib_common.bash
die()        { err=${1-1}; shift; [ -z ${1+x} ] || printError "OLD $@"; exit $err ; }
printDebug() { ((DEBUG)) && echo -e "$(date +'%F %T') \033[1;35mDEBUG  :\033[0;35m ${@}\033[0m" ; }
printError() {              echo -e "$(date +'%F %T') \033[1;91mERROR  :\033[0;91m ${@}\033[0m" ; }
if ! command -v realpath &>/dev/null ; then realpath() { readlink -- "$1" ; } ; fi



#-------------------------------------------------------------------------------
# path to this script - needs GNU `realpath` installed
#-------------------------------------------------------------------------------

# Todo: Use source lib_coreutils.bash only during development
# Todo: else photo_check_dependencies() adds coreutils to the PATH
source "$( dirname $( realpath "${BASH_SOURCE[0]}" ) )/lib_coreutils.bash" || die 53 "Library lib_coreutils.bash was not found."

readonly _THIS_SCRIPT="$( realpath "${BASH_SOURCE[0]}" )" # full path to script
readonly _THIS=$( basename "$_THIS_SCRIPT" )              # script name
readonly _THIS_DIR="$( dirname $_THIS_SCRIPT )"           # path to script dir

printDebug "_THIS_SCRIPT  = $_THIS_SCRIPT"
printDebug "_THIS         = $_THIS"
printDebug "_THIS_DIR     = $_THIS_DIR"



#-------------------------------------------------------------------------------
# load some function libraries
#-------------------------------------------------------------------------------

source "$_THIS_DIR/lib_common.bash" && ((common_lib_loaded)) || die 53 "Library lib_common.bash was not found."
#source "$_THIS_DIR/lib_exif.bash"   && ((exif_lib_loaded))   || die 53 "Library lib_exif.bash was not found."
source "$_THIS_DIR/lib_photo.bash"  && ((photo_lib_loaded))  || die 53 "Library lib_photo.bash was not found."



#-------------------------------------------------------------------------------
# load config file(s), last one found overwrites all the previous ones
#-------------------------------------------------------------------------------

for d in "$_THIS_DIR" ~/.config/antu-photo ~ . ; do
	source "$d/.antu-photo.cfg" 2>/dev/null || \
	source "$d/antu-photo.cfg"  2>/dev/null
done
((ANTU_PHOTO_CFG_LOADED)) || die 51 "No config file antu-photo.cfg found"

#photo_config_directories_wrk
#photo_config_directories_nas
#photo_config_directories_rmt



#-------------------------------------------------------------------------------
# check directories
#-------------------------------------------------------------------------------

# If NAS was not mounted, then use a local logfile
photo_NASisMounted || LOGFILE="${DIR_PIC%/}/.antu-photo.log"

#photo_check_dependencies
#photo_check_directories
#photo_check_files

((ROTATE_LOGFILE)) && rotateLog $LOGFILE $ROTATE_LOGFILE




################################################################################
# MAIN
################################################################################

printToLog '-------------------------------------------------------------------'
printToLog "$_THIS started by ${USER:-${USERNAME:-${LOGNAME}}}"

# work in calling directory

case "$#" in
    0) printWarning "No FILENAME and no DIRNAME given. Assuming current directory." ;;
    1) ;;
    *) die "USAGE: ${0##*/} [FILENAME|DIRNAME]";;
esac

DIR="${1:-$(pwd)}"
_YY=$( date +%Y )

if [[ -d "$DIR" ]]; then
	FIND_ARG=''
else
	FIND_ARG="-name $(basename "$DIR" | sed 's/ /?/g')"
	DIR='.'
fi

find ${MAC:+-E} "${DIR%/}" $FIND_ARG -type f -print0 | while IFS= read -r -d $'\0' file; do
	photo_parse_filename "$file"
	read dn bn tr t1 ex e1 sq bu yy mm dd hh mi ss cs <<< "${REPLY[@]// /?}"
	#printDebugVar dn bn tr t1 ex e1 sq bu yy mm dd hh mi ss cs

	if (( yy > _YY )); then
		printWarning "The interpreted date would be from the future year $yy. The file ${bn//\?/ } was not renamed"
	elif (( yy < 1815 )); then
		printWarning "The interpreted year $yy would be from before photography existed. The file ${bn//\?/ } was not renamed"
	else
		new_file="${dn//\?/ }/${yy}${mm}${dd}-${hh}${mi}${ss}.${ex##*.}"
		mv -n "$file" "$new_file"
		touch -t "${yy}${mm}${dd}${hh}${mi}.${ss}" "$new_file"
		printToLog "renamed $file -> $new_file"
	fi
done
