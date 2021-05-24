#!/bin/bash
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
# 2015-11-08 AnTu initial version


#!#####################
echo "needs rewrite" #!
exit 1               #!
#!#####################



DIR_PIC=~/Pictures/2015/

# MAIN
cd $DIR_PIC

# set permissions
find . -type d ! -path "*.photoslibrary/*" -exec chmod --changes 755 {} \;
find . -type f ! -path "*.photoslibrary/*" -exec chmod --changes 644 {} \;

# rename wrong extensions
find . -name "*.jpeg" ! -path "*.photoslibrary/*" -exec bash -c 'mv -n "$1" "${1%.*}.JPG"'  _ {} \;
find . -name "*.tif"  ! -path "*.photoslibrary/*" -exec bash -c 'mv -n "$1" "${1%.*}.TIFF"' _ {} \;

# make most used file extensions capital
find . -name "*.arw"  ! -path "*.photoslibrary/*" -exec bash -c 'mv -n "$1" "${1%.*}_.arw"; mv -n -v "${1%.*}_.arw" "${1%.*}.ARW"' _ {} \;
find . -name "*.dng"  ! -path "*.photoslibrary/*" -exec bash -c 'mv -n "$1" "${1%.*}_.dng"; mv -n -v "${1%.*}_.dng" "${1%.*}.DNG"' _ {} \;
find . -name "*.gif"  ! -path "*.photoslibrary/*" -exec bash -c 'mv -n "$1" "${1%.*}_.gif"; mv -n -v "${1%.*}_.gif" "${1%.*}.GIF"' _ {} \;
find . -name "*.jpg"  ! -path "*.photoslibrary/*" -exec bash -c 'mv -n "$1" "${1%.*}_.jpg"; mv -n -v "${1%.*}_.jpg" "${1%.*}.JPG"' _ {} \;
find . -name "*.png"  ! -path "*.photoslibrary/*" -exec bash -c 'mv -n "$1" "${1%.*}_.png"; mv -n -v "${1%.*}_.png" "${1%.*}.PNG"' _ {} \;
find . -name "*.tif"  ! -path "*.photoslibrary/*" -exec bash -c 'mv -n "$1" "${1%.*}_.tif"; mv -n -v "${1%.*}_.tif" "${1%.*}.TIF"' _ {} \;

# renumber series (if <file>_2.* and <file>.* exist, rename latter to <file>_0.*)
find . -name "*_2.*" ! -path "*.photoslibrary/*" -exec bash -c 'mv -n -v "${1%_*}.${1##*.}" "${1%_*}_0.${1##*.}"' _ {} \;
