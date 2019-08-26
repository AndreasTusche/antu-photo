#!/bin/bash
#
# NAME
#   photo-sort-time-frame.bash - recursivly rename and sort photos by creation date and frame number
# 
# SYNOPSIS
#   photo-sort-time-frame.bash [INDIR [OUTDIR]]
#
# DESCRIPTION
#   This moves files from     present directory and subfolders
#               to       ~/Pictures/sorted/YYYY/YYYY-MM-DD/
#
# Images and RAW images are renamed to YYYYMMDD-hhmmss_ffff.xxx, based on
#   their CreateDate and Frame Number. Frame Numbers usually only exist where an
#   analouge series of photos was digitalised. If two pictures still end up in
#   the same file-name, it will then be suffixed with a an incremental number:
#   YYYYMMDD-hhmmss_ffff_n.xxx .
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
# 2017-04-15 AnTu created
# 2018-12-30 AnTu now checking for SequenceNumber
# 2019-08-25 AnTu corrected syntax for handling of SequenceNumber

DEBUG=1

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

# @ToDo: Sidecar files .cos .dop .nks .pp3 .?s.spd .xmp 
printInfo  "... sorting by time and sequence number (if any)"
exiftool -ext "*" --ext DS_Store --ext localized -i SYMLINKS \
	-if '$SequenceNumber' -if '$SequenceNumber ne "Single"' -if '$SequenceNumber ne 0' \
	-m -r -progress: -q ${DEBUG:+"-v"} \
	-d "${OUTDIR%/}/%Y/%Y-%m-%d/%Y%m%d-%H%M%S"\
	'-FileName<${FileModifyDate}_${SequenceNumber;s/\b(\d)\b/0$1/g}%+2c.${FileTypeExtension}'\
	'-FileName<${ModifyDate}_${SequenceNumber;s/\b(\d)\b/0$1/g}%+2c.${FileTypeExtension}'\
	'-FileName<${DateTimeOriginal}_${SequenceNumber;s/\b(\d)\b/0$1/g}%+2c.${FileTypeExtension}'\
	'-FileName<${CreateDate}_${SequenceNumber;s/\b(\d)\b/0$1/g}%+2c.${FileTypeExtension}'\
	"${INDIR}" | tee -a ${LOGFILE} | grep -v "(failed condition)"
	
printInfo "... sorting by time and frame (if any)"
exiftool -ext "*" --ext DS_Store --ext localized -i SYMLINKS \
    -if '$FrameNumber' -m -r -progress: -q  ${DEBUG:+"-v"} \
    -d "${OUTDIR%/}/%Y/%Y-%m-%d/%Y%m%d-%H%M%S"\
    '-FileName<${FileModifyDate}_${FrameNumber;s/\b(\d)\b/0$1/g}%+2c.${FileTypeExtension}'\
    '-FileName<${ModifyDate}_${FrameNumber;s/\b(\d)\b/0$1/g}%+2c.${FileTypeExtension}'\
    '-FileName<${DateTimeOriginal}_${FrameNumber;s/\b(\d)\b/0$1/g}%+2c.${FileTypeExtension}'\
    '-FileName<${CreateDate}_${FrameNumber;s/\b(\d)\b/0$1/g}%+2c.${FileTypeExtension}'\
    "${INDIR}" | tee -a ${LOGFILE} | grep -v "(failed condition)"

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
