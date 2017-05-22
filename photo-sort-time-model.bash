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
#		             to       ~/Pictures/sorted/YYYY/YYYY-MM-DD/
#
#	Images and RAW images are renamed to YYYYMMDD-hhmmss-model.xxx, based on
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
#	@author     Andreas Tusche
#	@copyright  (c) 2017, Andreas Tusche 
#	@package    antu-photo
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# when       who  what
# 2017-04-14 AnTu created

# config
DIR_PIC=~/Pictures/sorted/

# --- nothing beyond this line needs configuration -----------------------------
for d in "${0%/*}" ~ . ; do source "$d/.antu-photo.cfg"  2>/dev/null || source "$d/antu-photo.cfg" 2>/dev/null; done
 
INDIR="$(  readlink -f "${1:-$(pwd)}" )"
OUTDIR="$( readlink -f "${2:-${DIR_PIC}}" )"

exiftool -ext "*" --ext DS_Store --ext localized -i SYMLINKS \
    -if '$Model' -m -r -progress: -q \
    -d "${OUTDIR%/}/%Y/%Y-%m-%d/%Y%m%d-%H%M%S"\
    '-FileName<${FileModifyDate}-${Model;s/ /_/g;s/__+/-/g}%+c.${FileTypeExtension}'\
    '-FileName<${ModifyDate}-${Model;s/ /_/g;s/__+/-/g}%+c.${FileTypeExtension}'\
    '-FileName<${DateTimeOriginal}-${Model;s/ /_/g;s/__+/-/g}%+c.${FileTypeExtension}'\
    '-FileName<${CreateDate}-${Model;s/ /_/g;s/__+/-/g}%+c.${FileTypeExtension}'\
    "${INDIR}"
exiftool -ext "*" --ext DS_Store --ext localized -i SYMLINKS \
    -m -r -progress: -q \
    -d "${OUTDIR%/}/%Y/%Y-%m-%d/%Y%m%d-%H%M%S%%+c.%%le"\
    "-FileName<FileModifyDate"\
    "-FileName<ModifyDate"\
    "-FileName<DateTimeOriginal"\
    "-FileName<CreateDate"\
    "${INDIR}"
    