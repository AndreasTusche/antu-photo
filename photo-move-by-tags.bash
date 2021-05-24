#!/bin/bash
# -*- mode: bash; tab-width: 4 -*-
################################################################################
#
# NAME
#   photo-move-by-tags.bash - move to subdirectories
#
# USAGE
#   photo-move-by-tags.bash [-csv] [FILENAME|DIRNAME]
#
# DESCRIPTION
#	Move files to subdirectories according to the value of the Exif tags 
#		Make, Model, Software, ColorMode
#
# OPTIONS
#	-csv  Note the found tags in the file exif.csv before moving the files
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
# 2021-05-21 AnTu created

if [[ "$1" == "-csv" ]]; then
	shift
	exiftool -m --ext csv -csv -Make -Model -Software -ColorMode "${1:-.}" >exif.csv
fi

exiftool -m --ext csv '-Directory<${Make;}_${Model;}_${Software;}_${ColorMode;}' "${1:-.}"
