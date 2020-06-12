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
#	@author     Andreas Tusche    <antu-photo@andreas-tusche.de>
#	@copyright  (c) 2017-2019, Andreas Tusche <www.andreas-tusche.de>
#	@package    antu-photo
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# when       who  what
# ---------- ---- --------------------------------------------------------------
# 2017-04-15 AnTu created
# 2018-10-03 AnTu trash both, image and RAW
# 2019-10-22 AnTu check external drives Trashes

# config
#DEBUG=1

# --- nothing beyond this line needs configuration -----------------------------
if [ "$ANTU_PHOTO_CFG_DONE" != "1" ] ; then # read the configuration file(s)
	for d in "${0%/*}" ~ . ; do source "$d/.antu-photo.cfg" 2>/dev/null || source "$d/antu-photo.cfg" 2>/dev/null; done
fi
if [ "$ANTU_PHOTO_CFG_DONE" != "1" ] ; then # if sanity check failed
	echo -e "\033[01;31mERROR:\033[00;31m Config File antu-photo.cfg was not found\033[0m" >&2 
	exit 1
fi

(($PHOTO_LIB_DONE)) || source "$LIB_antu_photo"
if [ "$PHOTO_LIB_DONE" != "1" ] ; then # if sanity check failed
	echo -e "\033[01;31mERROR:\033[00;31m Library $LIB_antu_photo was not found\033[0m" >&2
	exit 1
fi


for rcyDir in ${DIR_RCY} /Volumes/*/.Trashes/* ; do

	cd ${rcyDir}

	# for each RAW trash the corresponding image
	find ${MAC:+-E} . -iregex ".*/${RGX_DAT%/}(_[0-9][0-9]?)?\.(${RGX_RAW})" -type f -print0 | while IFS= read -r -d $'\0' file; do
		fn="${file##*/}"   # full file name
		bn="${fn%.*}"      # file base name 
		yy="${fn:0:4}"     # year 
		mm="${fn:4:2}"     # month
		dd="${fn:6:2}"     # day
	    mv -v ${DIR_PIC_2%/}/$yy/$yy-$mm-$dd/$bn.* ${DIR_RCY}/ 2>/dev/null
	    mv -v ${DIR_SRC_2%/}/$yy/$yy-$mm-$dd/$bn.* ${DIR_RCY}/ 2>/dev/null
	done

	# for each image trash the corresponding RAW
	find ${MAC:+-E} . -iregex ".*/${RGX_DAT%/}(_[0-9][0-9]?)?\.(${RGX_IMG})" -type f -print0 | while IFS= read -r -d $'\0' file; do
		fn="${file##*/}"   # full file name
		bn="${fn%.*}"      # file base name 
		yy="${fn:0:4}"     # year 
		mm="${fn:4:2}"     # month
		dd="${fn:6:2}"     # day
	    mv -v ${DIR_RAW%/}/$yy/$yy-$mm-$dd/$bn.* ${DIR_RCY}/ 2>/dev/null
	done

done
