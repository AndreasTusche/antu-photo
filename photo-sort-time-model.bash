#!/bin/bash
#
# NAME
#   photo-sort-time-model.bash - recursivly rename and sort photos by creation date and camera model
# 
# SYNOPSIS
#   photo-sort-time-model.bash [INDIR [OUTDIR]]
#
# DESCRIPTION
#   This moves files from     present directory and subfolders
#               to       ~/Pictures/sorted/YYYY/YYYY-MM-DD/
#
# Images and RAW images are renamed to YYYYMMDD-hhmmss-model.xxx, based on
#   their CreateDate and Camera Model Name. If two pictures were taken at the
#   same second by the same camera, the filename will be suffixed with a an
#   incremental number: YYYYMMDD-hhmmss-model_n.xxx .
#
# OPTIONS
#   INDIR  defaults to the present working directory
#   OUTDIR defaults to ~/Pictures/sorted/
#
# FILES
#	Uses exiftool (http://www.sno.phy.queensu.ca/~phil/exiftool/)
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
# 2017-04-14 AnTu created
# 2019-08-25 AnTu code clean-up

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


INDIR="$(  readlink -f "${1:-$(pwd)}" )"
OUTDIR="$( readlink -f "${2:-${DIR_PIC}}" )"

printToLog "--- ${0##*/} called"
printToLog "... INDIR  = $INDIR"
printToLog "... OUTDIR = $OUTDIR"

printInfo "... sorting by camera model"
exiftool -ext "*" --ext DS_Store --ext localized -i SYMLINKS \
    -if '$Model' -m -r -progress: -q \
    -d "${OUTDIR%/}/%Y/%Y-%m-%d/%Y%m%d-%H%M%S"\
    '-FileName<${FileModifyDate}-${Model;s/ /_/g;s/__+/-/g}%+2c.${FileTypeExtension}'\
    '-FileName<${ModifyDate}-${Model;s/ /_/g;s/__+/-/g}%+2c.${FileTypeExtension}'\
    '-FileName<${DateTimeOriginal}-${Model;s/ /_/g;s/__+/-/g}%+2c.${FileTypeExtension}'\
    '-FileName<${CreateDate}-${Model;s/ /_/g;s/__+/-/g}%+2c.${FileTypeExtension}'\
    "${INDIR}"

printInfo "... sorting by time stamps"
exiftool -ext "*" --ext DS_Store --ext localized -i SYMLINKS \
    -if2 '$CreateDate || $DateTimeOriginal || $ModifyDate' -m -r -progress: -q  ${DEBUG:+"-v"} \
    -d "${OUTDIR%/}/%Y/%Y-%m-%d/%Y%m%d-%H%M%S"\
    '-FileName<${ModifyDate}%+2c.${FileTypeExtension}'\
    '-FileName<${DateTimeOriginal}%+2c.${FileTypeExtension}'\
    '-FileName<${CreateDate}%+2c.${FileTypeExtension}'\
    "${INDIR}" | tee -a ${LOGFILE}

# not ideal but the last resort to get a timestamp
# (having this in above block did not work for some reason)
printInfo "... sorting remaining by file times"
exiftool -ext "*" --ext DS_Store --ext localized -i SYMLINKS \
    -fast -m -r -progress: -q  ${DEBUG:+"-v"} \
    -d "${OUTDIR%/}/%Y/%Y-%m-%d/%Y%m%d-%H%M%S"\
    '-FileName<${FileModifyDate}%+2c.${FileTypeExtension}'\
    "${INDIR}" | tee -a ${LOGFILE}
