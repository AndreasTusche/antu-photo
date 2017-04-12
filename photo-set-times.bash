#!/bin/bash
# photo-set-times.bash - set date and time to a fixed date
#
# This set the date and time stamps of all picture files to the given date in
# the given directory.
#
# USAGE
#   photo-set-times.bash YYYY:MM:DD hh:mm:ss DIRNAME
#
# when       who  what
# 2017-04-11 AnTu initial release

T="${1//-/:} ${2//-/:}"
DIRNAME="$( readlink -f "${3:-$(pwd)}" )"

if [[ "$#" -ne 3 ]]; then
    echo "USAGE: ${0##*/} YYYY:MM:DD hh:mm:ss DIRNAME"
	exit 1
fi

exiftool --ext avi --ext bmp --ext moi --ext mpg --ext mts -m -overwrite_original_in_place -q -r -CreateDate="$T" -DateTimeOriginal="$T" -SonyDateTime="$T" -ModifyDate="$T" -FileModifyDate="$T" $DIRNAME
