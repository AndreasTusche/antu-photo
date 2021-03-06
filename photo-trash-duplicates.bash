#!/bin/bash
#
# NAME
#   photo-trash-duplicates.bash - recursivly moves duplicates to the Trash
# 
# SYNOPSIS
#   photo-trash-duplicates.bash [INDIR] [TODIR] [TRASH]
#
# DESCRIPTION
# 	This script finds files ending in a sequence number _nn and compares the
#	checksums of files with the same base name (i.e. up to the date and time
#	stamp). It then moves all but one of the duplicate files to the User's
#	Trash directory.
#	In order to benefit from Apple's "Put Back" function, this script uses
#	Apple Script functions.
#
# OPTIONS
#   INDIR  This directory and all its subdirectories are searched for files
#	       with the file name tsrating in a timestamp like "yyyymmdd-HHMMSS".
#          Defaults to the present working directory
#
#	TODIR  A directory with a subdirectory structure ""./yyyy/yyyy-mm-dd/" which
#	       then is searched for identical files of the same date and time as
#          found in the INDIR.
#
# AUTHOR
# @author     Andreas Tusche
# @copyright  (c) 2018, Andreas Tusche 
# @package    antu-photo
# @version    $Revision: 0.0 $
# @(#) $Id: . Exp $
#
# when       who  what
# 2018-12-29 AnTu created

DEBUG=1

# --- nothing beyond this line needs configuration -----------------------------
for d in "${0%/*}" ~ . ; do source "$d/.antu-photo.cfg" 2>/dev/null || source "$d/antu-photo.cfg" 2>/dev/null; done

INDIR="$(  readlink -f "${1:-$(pwd)}" )"
TODIR="$(  readlink -f "${2:-${DIR_PIC_2%/}}" )"
TRASH="$(  readlink -f "${3:-${DIR_RCY%/}}" )"

(($DEBUG)) && echo "--- trash-duplicates"
(($DEBUG)) && echo "... INDIR  = $INDIR"
(($DEBUG)) && echo "... TODIR  = $TODIR"
(($DEBUG)) && echo "... TRASH  = $TRASH"

#if [[ "${INDIR%/}" == "${DIR_SRC_2%/}" || "${INDIR%/}" == "${DIR_TMP%/}" ]]; then
	(($DEBUG)) && echo "... compare all files from ${INDIR%/}"
	RGX=".*/${RGX_DAT%/}.*"
#else
#	(($DEBUG)) && echo "... compare files with sequence number"
#	RGX=".*/${RGX_DAT%/}_[0-9]+(_[0-9]+)?\..*"
#fi

IFS='
'
for candidate in $(
	# Find files for comparison
	find ${MAC:+-E} -x "$INDIR" -regex "$RGX" -type f -print0 |#
		while IFS= read -r -d $'\0' file; do
			fn="${file##*/}"   # full file name
			dn="${file%/*}"    # directory name
			b0="${fn%%.*}"     # file base name
			bn="${b0%%_*}"     # file base name, without sequence number
			yy="${fn:0:4}"     # year 
			mm="${fn:4:2}"     # month
			dd="${fn:6:2}"     # day
			# list files of same basename
			echo "searching files of date $bn" >/dev/stderr
			if [[ "${INDIR%/}" != "${TODIR%/}" ]] ; then
				ls -1 "${TODIR%/}/$yy/$yy-$mm-$dd/$bn"* 2>/dev/null
			fi
			ls -1 "$dn/$bn"*
		done |#
	sort -u
); do
	echo "candidate $candidate" >/dev/stderr
	# use checksums to identify duplicates
	md5 -r "$candidate"
done |#
sort |#
uniq -D -w 32 |#
awk '
# list all but one duplicates
$1==hash {
	hash=$1
	$1=""
	sub(/^[ \t\r\n]+/, "", $0)
	print "echo trashing duplicate" $0
	print "mv \"" $0 "\" '$TRASH'"
	next}
{hash=$1}
' |#
sh