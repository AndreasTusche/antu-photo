#!/bin/bash
#
# NAME
#   photo-shift-times.bash - shift date and time by a fixed number of seconds
#
# SYNOPSIS
#   photo-shift-times.bash SECONDS [FILENAME|DIRNAME]
#
# DESCRIPTION
#   This shifts the date and time stamps by the given number of seconds for one
#   picture file or for all pictures in the given directory (not recursive).
#
#   Following timestamps are modified if they existed before:
#       CreateDate
#       DateTimeOriginal
#       SonyDateTime
#       SonyDateTime2
#       ModifyDate
#       FileModifyDate
#
#   It is recommended to then move and rename the modified files using
#       photo-sort-time.bash 
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
# 2017-04-14 AnTu created
# 2017-05-06 AnTu added support for SonyDateTime2

T=$(bc <<< 1*0${1//[^-0-9]/})          # make sure we have a number
DIRNAME="$( readlink -f "${2:-$(pwd)}" )"

case "$#" in
    1) echo "WARNING: No FILENAME and no DIRNAME given. Assuming current directory. All files in $DIRNAME will be shifted by $T seconds." ;;
    2) ;;
    *) echo "USAGE: ${0##*/} SECONDS [FILENAME|DIRNAME]"; exit 1;;
esac

if [[ $T > 0 ]]; then
    exiftool --ext avi --ext bmp --ext moi --ext mpg --ext mts \
        -m -overwrite_original_in_place -progress: -q \
        -AllDates+="::$T" -SonyDateTime+="::$T" -SonyDateTime2+="::$T" -IFD1:ModifyDate+="::$T" -FileModifyDate+="::$T" \
        $DIRNAME
else
    T=$(bc <<< -1*${T})                # make sure we have a positive number
    exiftool --ext avi --ext bmp --ext moi --ext mpg --ext mts \
        -m -overwrite_original_in_place -progress: -q \
        -AllDates-="::$T" -SonyDateTime-="::$T" -SonyDateTime2-="::$T" -IFD1:ModifyDate-="::$T" -FileModifyDate-="::$T" \
        $DIRNAME
fi
