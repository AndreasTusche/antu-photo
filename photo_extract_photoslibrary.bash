#!/bin/bash
#
# NAME
# antu_extractphotolibrary.bash - retrieve photos from Apple Photo Libraries
#
# SYNOPSIS
# antu_extractphotolibrary.bash LIBRARY
#
# DESCRIPTION
#  * recursevly moves photos from  LIBRARY/Masters/ to ~/Pictures/
#
# AUTHOR
#	@author     Andreas Tusche    <antu-photo@andreas-tusche.de>
#	@copyright  (c) 2017-2019, Andreas Tusche <www.andreas-tusche.de>
#	@package    antu-photo
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# when       who  what
# ---------- ---- --------------------------------------------------------------
# 2015-11-05 AnTu initial version
# 2019-08-25 AnTu use library functions

# default config
export DEBUG=1
export VERBOSE=1

# --- nothing beyond this line needs configuration -----------------------------
if [ "$ANTU_PHOTO_CFG_DONE" != "1" ] ; then # read the configuration file(s)
	for d in "${0%/*}" ~ . ; do source "$d/.antu-photo.cfg" 2>/dev/null || source "$d/antu-photo.cfg" 2>/dev/null; done
fi
if [ "$ANTU_PHOTO_CFG_DONE" != "1" ] ; then # if sanity check failed
	echo -e "\033[01;31mERROR:\033[00;31m Config File antu-photo.cfg was not found\033[0m" >&2 
	exit 1
fi

(($PHOTO_LIB_DONE)) || source "$LIB_antu_photo"
if [ "$PHOTO_LIB_DONE" != "1" ] ; then # if sanity check failed
	echo -e "\033[01;31mERROR:\033[00;31m Library $LIB_antu_photo was not found\033[0m" >&2
	exit 1
fi


# === MAIN =====================================================================

if [ "$1" == "" ]; then exit ; fi
cd "$1"
find Masters -type f -exec mv -v --backup=t "{}" ${DIR_PIC} \;
photo_align_backup_file_names "."
