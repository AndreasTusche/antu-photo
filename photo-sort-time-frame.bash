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
#		             to       ~/Pictures/sorted/YYYY/YYYY-MM-DD/
#
#	Images and RAW images are renamed to YYYYMMDD-hhmmss_ffff.xxx, based on
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
#	@author     Andreas Tusche
#	@copyright  (c) 2017, Andreas Tusche 
#	@package    antu-photo
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# when       who  what
# 2017-04-15 AnTu created

# config
DIR_PIC=~/Pictures/sorted/

# --- nothing beyond this line needs configuration -----------------------------
for d in "${0%/*}" ~ . ; do source "$d/.antu-photo.cfg" 2>/dev/null || source "$d/antu-photo.cfg" 2>/dev/null; done
 
INDIR="$(  readlink -f "${1:-$(pwd)}" )"
OUTDIR="$( readlink -f "${2:-${DIR_PIC}}" )"

exiftool -ext "*" --ext DS_Store --ext localized -i SYMLINKS -if '$FrameNumber' -m -r -v \
    -d "${OUTDIR%/}/%Y/%Y-%m-%d/%Y%m%d-%H%M%S"\
    '-FileName<${FileModifyDate}_${FrameNumber}%+c.${FileTypeExtension}'\
    '-FileName<${ModifyDate}_${FrameNumber}%+c.${FileTypeExtension}'\
    '-FileName<${DateTimeOriginal}_${FrameNumber}%+c.${FileTypeExtension}'\
    '-FileName<${CreateDate}_${FrameNumber}%+c.${FileTypeExtension}'\
    "${INDIR}"
exiftool -ext "*" --ext DS_Store --ext localized -i SYMLINKS -m -r -v \
    -d "${OUTDIR%/}/%Y/%Y-%m-%d/%Y%m%d-%H%M%S%%+c.%%le"\
    "-FileName<FileModifyDate"\
    "-FileName<ModifyDate"\
    "-FileName<DateTimeOriginal"\
    "-FileName<CreateDate"\
    "${INDIR}"
    