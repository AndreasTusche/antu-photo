#!/bin/bash
#
# NAME
#	photo-extract-gps.bash - recursively extract GPS coordinates from image files
# 
# SYNOPSIS
#	photo-extract-gps.bash DIRNAME
#
# DESCRIPTION
#	This extracts GPS geo-location information from files in the given
#	directory and subfolders and writes the result in GPX format to stdout.
#
# OPTIONS
#	DIRNAME defaults to the present working directory
#
# FILES
#	Uses exiftool (http://www.sno.phy.queensu.ca/~phil/exiftool/geotag.html)
#
# AUTHOR
# @author     Andreas Tusche
# @copyright  (c) 2017-2019, Andreas Tusche 
# @package    antu-photo
# @version    $Revision: 0.0 $
# @(#) $Id: . Exp $
#
# when       who  what
# 2017-04-17 AnTu created

# config ( will be overwritten if config file exists )
GPS_FMT="${0%/*}/gpx.fmt"
GPS_LOG=gps.gpx #@ToDo: extract date info and have output to yyyymmdd.gpx


# --- nothing beyond this line needs configuration -----------------------------
for d in "${0%/*}" ~ . ; do source "$d/.antu-photo.cfg" 2>/dev/null || source "$d/antu-photo.cfg" 2>/dev/null; done
 
#INDIR="$(  readlink -f "${1:-$(pwd)}" )"
INDIR="${1:-$(pwd)}"

exiftool --ext DS_Store --ext gpx --ext localized -i SYMLINKS \
    -d %Y-%m-%dT%H:%M:%SZ -if '$GPSDateStamp' -fileOrder gpsdatetime -m -r -p ${GPS_FMT} -progress: -q \
    "${INDIR}"
    