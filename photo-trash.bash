#!/bin/bash
# -*- mode: bash; tab-width: 4 -*-
################################################################################
#
# NAME
#   photo-trash.bash - for each image in the trash move correspondings to trash
# 
# SYNOPSIS
#   photo-trash.bash [-n]
#
# DESCRIPTION
#   For each image in the Trash the corrsponding RAW file will be moved to the
#	Trash as well. Images are identified by a regular expression.
#	1st: for each RAW trash the corresponding image
#	2nd: for each image trash the corresponding RAW
#
# OPTIONS
#	-n	dry-run, print affected files but don't move any
#
# BUGS
#	Since version 10.11, Mac OS has got a new feature – SIP (System Integrity
#	Protection), in order to protect files from being modified by some malicious
#	software. SIP would even block you from deleted files and accessing files
#	from the Trash. 
#	In the antu-photo.cfg configuration file, you either have to
#	A) use a normal folder instead of the recycle bin (.Trash), or 
#	B) give the Terminal.app Full Disk permissions in the security settings, as
#	   described here: https://apple.stackexchange.com/questions/376916/
#
# AUTHOR
#	@author     Andreas Tusche    <antu-photo@andreas-tusche.de>
#	@copyright  (c) 2017-2021, Andreas Tusche <www.andreas-tusche.de>
#	@package    antu-photo
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# when       who  what
# ---------- ---- --------------------------------------------------------------
# 2017-04-15 AnTu created
# 2018-10-03 AnTu trash both, image and RAW
# 2019-10-22 AnTu check external drives Trashes

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

photo_config_directories_wrk
photo_config_directories_nas
photo_config_directories_rmt



#-------------------------------------------------------------------------------
# check directories
#-------------------------------------------------------------------------------

# If NAS was not mounted, then use a local logfile
photo_NASisMounted || LOGFILE="${DIR_PIC%/}/.antu-photo.log"

photo_check_dependencies # ToDo: also set PATH to GNU coreutils there
#photo_check_directories
#photo_check_files

((ROTATE_LOGFILE)) && rotateLog $LOGFILE $ROTATE_LOGFILE



################################################################################
# MAIN
################################################################################

printToLog '-------------------------------------------------------------------'
printToLog "$_THIS started by ${USER:-${USERNAME:-${LOGNAME}}}"

if [ "${1-}" == "-n" ]; then SIM=1; else SIM=; fi

for rcyDir in ${DIR_RCY} /Volumes/*/.Trashes/* ; do

	if [ -d "$rcyDir" ]; then
		cd "$rcyDir"

		ls >/dev/null # test if this trash is SIP protected
		(($?)) && break

		# for each RAW trash the corresponding image
		find ${MAC:+-E} . -iregex ".*/${RGX_DSQ%/}\.(${RGX_RAW})" -type f -print0 | while IFS= read -r -d $'\0' file; do
			photo_parse_filename "$file"
			read dn bn tr t1 ex e1 sq bu yy mm dd hh mi ss cs <<< "${REPLY[@]// /?}"
			${SIM:+echo} mv -v ${DIR_REV%/}/$yy/$yy-$mm-$dd/$tr.* ${DIR_RCY}/ 2>/dev/null | tee -a $LOGFILE
		done

		# for each image trash the corresponding RAW
		find ${MAC:+-E} . -iregex ".*/${RGX_DSQ%/}\.(${RGX_IMG})" -type f -print0 | while IFS= read -r -d $'\0' file; do
			photo_parse_filename "$file"
			read dn bn tr t1 ex e1 sq bu yy mm dd hh mi ss cs <<< "${REPLY[@]// /?}"
			${SIM:+echo} mv -v ${DIR_RAW%/}/$yy/$yy-$mm-$dd/$tr.* ${DIR_RCY}/ 2>/dev/null | tee -a $LOGFILE
		done
	fi
done
