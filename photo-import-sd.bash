#!/usr/bin/env bash
# -*- mode: bash; tab-width: 4 -*-
################################################################################
# NAME
#   photo-import-sd.bash - Import files from SD Card
#
# SYNOPSIS
#   photo-import-sd.bash
#
# DESCRIPTION
#	The mount point of SD Cards is different for each card. This scripts tries
#	to find it and then copies all Photos from the DCIM to the Inbox directory.
#	By the way, it does not keep track of past copy activities and hence this
#	script may produce a lot of duplicate files on your disk, if you don't
#	take care.
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
# 2019-01-01 AnTu created
# 2021-05-14 AnTu use my bash libraries


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

# preliminary functions, may be replaced by those from lib_common.bash
die()        { err=${1-1}; shift; [ -z ${1+x} ] || printError "OLD $@"; exit $err ; }
printDebug() { ((DEBUG)) && echo -e "$(date +'%F %T') \033[1;35mDEBUG  :\033[0;35m ${@}\033[0m" ; }
printError() {              echo -e "$(date +'%F %T') \033[1;91mERROR  :\033[0;91m ${@}\033[0m" ; }
if ! command -v realpath &>/dev/null ; then realpath() { readlink -- "$1" ; } ; fi



#-------------------------------------------------------------------------------
# path to this script - needs GNU `realpath` installed
#-------------------------------------------------------------------------------

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



#-------------------------------------------------------------------------------
# check directories
#-------------------------------------------------------------------------------

photo_check_dependencies
photo_check_directories



################################################################################
# MAIN
################################################################################

# find SD Card and its mount point (i.e its path)
if [[ "$DIR_DCF" == "" ]]; then
	# get all mounted disks
	list=$( diskutil list | awk '/0:/{printf $NF" "}')
	
	# search for SD Card Reader
	for i in $list; do
		diskutil info $i | grep "SD Card Reader" >/dev/null
		if [[ "$?" == "0" ]]; then
			sdCard=$i
			break
		fi
	done
	
	if [[ "$sdCard" == "" ]]; then
		printError "No SD Card found"
		exit 1
	else
		printDebug "SD Card on $sdCard"
	fi

	# get mount point of SD Card
	DIR_DCF=$( diskutil info ${sdCard}s1 | awk -F: '/Mount Point/{gsub(/^[ \t]+/, "", $2); print $2}' )
	printDebug "SD Card Path $DIR_DCF"
fi

# copy photos
cd $DIR_DCF/DCIM
rsync -rtv --partial-dir=$DIR_ERR . $DIR_SRC

