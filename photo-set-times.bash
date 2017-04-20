#!/bin/bash
#
# NAME
#   photo-set-times.bash - set date and time to a fixed date
#
# USAGE
#   photo-set-times.bash YYYY:MM:DD hh:mm:ss FILENAME
#   photo-set-times.bash YYYY:MM:DD hh:mm:ss [DIRNAME]
#
# DESCRIPTION
#   This sets the date and time stamps to the given date for one picture file or
#   for all picture files in the given directory (not recursive).
#
# Following timestamps are modified if they existed before:
#   CreateDate
#   DateTimeOriginal
#   SonyDateTime
#   ModifyDate
#   FileModifyDate
#
# FILES
#	Uses exiftool (http://www.sno.phy.queensu.ca/~phil/exiftool/)
#
# AUTHOR
#	@author     Andreas Tusche
#	@copyright  (c) 2017, Andreas Tusche 
#	@package    antu-photo
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# when       who  what
# 2017-04-11 AnTu created

T="${1//-/:} ${2//-/:}"
DIRNAME="$( readlink -f "${3:-$(pwd)}" )"

case "$#" in
    2) echo "WARNING: No FILENAME and no DIRNAME given. Assuming current directory. All files in $DIRNAME will be set to the time $T." ;;
    3) ;;
    *) echo "USAGE: ${0##*/} YYYY:MM:DD hh:mm:ss [FILENAME|DIRNAME]"; exit 1;;
esac

exiftool --ext avi --ext bmp --ext moi --ext mpg --ext mts \
    -m -overwrite_original_in_place -progress: -q \
    -CreateDate="$T" -DateTimeOriginal="$T" -SonyDateTime="$T" -ModifyDate="$T" -FileModifyDate="$T" \
    $DIRNAME
