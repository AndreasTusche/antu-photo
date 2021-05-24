#!/bin/bash
# -*- mode: bash; tab-width: 4 -*-
################################################################################
#
# NAME
#   photo-move-by-size.bash - move to subdirectories
#
# USAGE
#   photo-move-by-size.bash [-csv] [FILENAME|DIRNAME]
#
# DESCRIPTION
#	Move files to subdirectories according to the image size.
#
# OPTIONS
#	-csv  Note the image width and height in the file exif.csv before moving
#	      the files
#
# AUTHOR
#	@author     Andreas Tusche    <antu-photo@andreas-tusche.de>
#	@copyright  (c) 2021-2021, Andreas Tusche <www.andreas-tusche.de>
#	@package    antu-photo
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# when       who  what
# ---------- ---- --------------------------------------------------------------
# 2021-05-23 AnTu created

if [[ "$1" == "-csv" ]]; then
	shift
	exiftool -m --ext csv -csv -ImageWidth -ImageHeight -Orientation "${1:-.}" >exif.csv
fi

# Orientation 
#	1 = Horizontal (normal) 
#	2 = Mirror horizontal 
#	3 = Rotate 180 
#	4 = Mirror vertical 
#	5 = Mirror horizontal and rotate 270 CW
#	6 = Rotate 90 CW 
#	7 = Mirror horizontal and rotate 90 CW 
#	8 = Rotate 270 CW

exiftool -m --ext csv -if '$Orientation# ge 5' '-Directory<${ImageHeight}x${ImageWidth}' "${1:-.}"
exiftool -m --ext csv '-Directory<${ImageSize}' "${1:-.}"
