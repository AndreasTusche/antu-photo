#!/bin/bash -x
#
# NAME
#   photo-set-gps.bash - set GPS coordinates in image files
# 
# SYNOPSIS
#   photo-set-gps.bash DIRNAME
#
# DESCRIPTION
#   This extracts GPS geo-location information from files in the given
#   directory and subfolders and stores it in an GPX file, unless it is already
#   available in the same folder.
#
#   In a second step it sets(!) the GPS geo-location information for the other
#   files in the given directory and subfolders. Be aware that it will locate
#   the new positions on a straight line between known track-points.
#
# OPTIONS
#   DIRNAME defaults to the present working directory
#
# FILES
#	Uses exiftool (http://www.sno.phy.queensu.ca/~phil/exiftool/geotag.html)
#
# AUTHOR
#	@author     Andreas Tusche
#	@copyright  (c) 2017, Andreas Tusche 
#	@package    antu-photo
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# when       who  what
# 2017-04-17 AnTu created

# config ( will be overwritten if config file exists )
GPS_FMT="${0%/*}/gpx.fmt"
GPS_LOG=gps.gpx

# --- nothing beyond this line needs configuration -----------------------------
for d in "${0%/*}" ~ . ; do source "$d/.antu-photo.cfg" 2>/dev/null || source "$d/antu-photo.cfg" 2>/dev/null; done
 
INDIR="$( readlink -f "${1:-$(pwd)}" )"

# Step 1: extract GPS information and store it in GPX format, if not already existent
#         side-effect: this file will remain in the directory
if [[ ! -e "${INDIR%/}/${GPS_LOG}" ]]; then
    $CMD_extractgps "${INDIR}"  >"${INDIR%/}/${GPS_LOG}"
fi

# Step 2: identify image names that can be taken as geo-sync reference
if [[ -d "${INDIR}" ]]; then
    cd "${INDIR}"
fi
opt=$( exiftool -i SYMLINKS -if '$gpsdatetime' -fileOrder gpsdatetime -m -p '-geosync=$Filename ' -q "${INDIR}" )

# Step 3: set GPS coordiantes to files that don't have one yet, allow 3 hours
#         between way-points
exiftool --ext DS_Store --ext localized -i SYMLINKS \
    -api GeoMaxIntSecs=10800 -geotag "${INDIR%/}/${GPS_LOG}" $opt -m -P -wm cg \
    "${INDIR}"
