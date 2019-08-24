#!/bin/bash
#
# NAME
#   photo-import-sd.bash - Import files from SD Card
#
# SYNOPSIS
#   photo-import-sd.bash
#
# DESCRIPTION
#	The mount point of SD Cards is different for each card. This scripts tries
#	to find it and then copies all Photos from the DCIM to the Inbox directory.
#	By the way, it does not keep track of past copy activities and hence this
#	script may produce a lot of duplicate files on your disk, if you don't
#	take care.
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
# 2019-01-01 AnTu created

# default configs
DIR_DCF=''                             # mount point of SD Card
DIR_PIC=~/Pictures/                    # Local Pictures directory
DIR_SRC=${DIR_PIC%/}/INBOX/            # start point, files are moved from here to their destinations
DIR_ERR=${DIR_PIC%/}/ERROR/            # something went wrong, investigate

DEBUG=1

# --- nothing beyond this line needs configuration -----------------------------
for d in "${0%/*}" ~ . ; do source "$d/.antu-photo.cfg" 2>/dev/null || source "$d/antu-photo.cfg" 2>/dev/null; done
source "$LIB_antu_photo"

# === MAIN ===

# find SD Card and its mount point (i.e its path)
if [[ "$DIR_DCF" == "" ]]; then
	# get all mounted disks
	list=$( diskutil list | awk '/0:/{printf $NF" "}')
	
	# search for SD Card Reader
	for i in $list; do
		diskutil info $i | grep "SD Card Reader" >/dev/null
		if [[ "$?" == "0" ]]; then
			sdCard=$i
			break
		fi
	done
	
	if [[ "$sdCard" == "" ]]; then
		printError "No SD Card found"
		exit 1
	else
		printDebug "SD Card on $sdCard"
	fi

	# get mount point of SD Card
	DIR_DCF=$( diskutil info ${sdCard}s1 | awk -F: '/Mount Point/{gsub(/^[ \t]+/, "", $2); print $2}' )
	printDebug "SD Card Path $DIR_DCF"
fi

# copy photos
cd $DIR_DCF/DCIM
rsync -rtv --partial-dir=$DIR_ERR . $DIR_SRC

