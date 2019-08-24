#!/bin/bash
#
# NAME
#   photo-trash.bash - for each image in the trash move correspondings to trash
# 
# SYNOPSIS
#   photo-trash.bash
#
# DESCRIPTION
#   For each image in the Trash the corrsponding RAW file will be moved to the
#	Trash as well. Images are identified by a regular expression.
#	1st: for each RAW trash the corresponding image
#	2nd: for each image trash the corresponding RAW
#
# AUTHOR
# @author     Andreas Tusche
# @copyright  (c) 2017, Andreas Tusche 
# @package    antu-photo
# @version    $Revision: 0.0 $
# @(#) $Id: . Exp $
#
# when       who  what
# ---------- ---- --------------------------------------------------------------
# 2017-04-15 AnTu created
# 2018-10-03 AnTu trash both, image and RAW

# config
#DEBUG=1

# --- nothing beyond this line needs configuration -----------------------------
if [ "$ANTU_PHOTO_CFG_DONE" != "1" ] ; then
	for d in "${0%/*}" ~ . ; do source "$d/.antu-photo.cfg" 2>/dev/null || source "$d/antu-photo.cfg" 2>/dev/null; done
fi
(($PHOTO_LIB_DONE)) || source "$LIB_antu_photo"


cd ${DIR_RCY}

# for each RAW trash the corresponding image
find ${MAC:+-E} . -iregex ".*/${RGX_DAT%/}(_[0-9][0-9]?)?\.(${RGX_RAW})" -type f -print0 | while IFS= read -r -d $'\0' file; do
	fn="${file##*/}"   # full file name
	bn="${fn%.*}"      # file base name 
	yy="${fn:0:4}"     # year 
	mm="${fn:4:2}"     # month
	dd="${fn:6:2}"     # day
    mv -v ${DIR_PIC%/}/$yy/$yy-$mm-$dd/$bn.* . 2>/dev/null
done

# for each image trash the corresponding RAW
find ${MAC:+-E} . -iregex ".*/${RGX_DAT%/}(_[0-9][0-9]?)?\.(${RGX_IMG})" -type f -print0 | while IFS= read -r -d $'\0' file; do
	fn="${file##*/}"   # full file name
	bn="${fn%.*}"      # file base name 
	yy="${fn:0:4}"     # year 
	mm="${fn:4:2}"     # month
	dd="${fn:6:2}"     # day
    mv -v ${DIR_RAW%/}/$yy/$yy-$mm-$dd/$bn.* . 2>/dev/null
done
