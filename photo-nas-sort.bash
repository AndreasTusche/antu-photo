#!/bin/bash
#
# NAME
# photo-nas-sort.bash - sort original photos from NAS INBOX to folders
#
# SYNOPSIS
# photo-nas-sort.bash
#
# DESCRIPTION
# Photos are expected to already have final desired filenames, e.g.
# 	YYYYMMDD-hhmmss[_f].xxx
# and are located in the NAS::Pictures/INBOX folder. This script moves
# 	* original images from     NAS::Pictures/INBOX/ and subfolders
#                     to       NAS::Pictures/ORIGINAL/YYYY/YYYY-MM-DD/
#	* created DNG     from     NAS::Pictures/INBOX/ and subfolders
#                     to       NAS::Pictures/ARCHIV/YYYY/YYYY-MM-DD/
#	* 4K JPGs         from     NAS::Pictures/INBOX/ and subfolders
#                     to       NAS::Pictures/JPG4K/YYYY/YYYY-MM-DD/
#
# The default direcories names can be overwritten by the antu-photo.cfg file.
#
# Raw images are recognised by their file extension:
#  .3fr .3pr .ari .arw .bay .cap .ce1 .ce2 .cib .cmt .cr2 .craw .crw .dc2
#  .dcr .dcs .dng .eip .erf .exf .fff .fpx .gray .grey .gry .iiq .kc2 .kdc
#  .kqp .lfr .mdc .mef .mfw .mos .mrw .ndd .nef .nop .nrw .nwb .olr .orf
#  .pcd .pef .ptx .r3d .ra2 .raf .raw .rw2 .rwl .rwz .sd[01] .sr2 .srf .srw
#  .st[45678] .stx .x3f .ycbcra
#
# FILES
#
# BUGS
#   - Companion files from 3rd party software are not renamed and may loose
#     their intended function.
#	@ToDo compare filenames only for timestamps not sequence numbers, see also trash-duplicates.
#	@ToDO if new sequence numbers are needed then use two digits
#
# AUTHOR
# @author     Andreas Tusche
# @copyright  (c) 2018, Andreas Tusche
# @package    antu-photo
# @version    $Revision: 0.0 $
# @(#) $Id: . Exp $
#

# default config
DEBUG=0
VERBOSE=1

if [[ "${OSTYPE:0:6}" == "darwin" ]]; then MAC=1; fi
if [[ "${OSTYPE:0:6}" == "cygwin" ]]; then WIN=1; fi

# Your preferred destination directories on the NAS
NAS_MNT=/Volumes/Pictures              # Mount point for NAS pictures directory
NAS_ARC=${NAS_MNT%/}/ARCHIV/           # for created DNG images and XMP sidecars
NAS_CAR=${NAS_MNT%/}/EDIT/SideCar/     # for side-car files from DxO PhotoLab, Capture 1, etc.
NAS_EDT=${NAS_MNT%/}/EDIT/             # for edited images and sidecars
NAS_ERR=${NAS_MNT%/}/ERROR/            # something went wrong, investigate
NAS_DUP=${NAS_MNT%/}/ERROR/DUPLICATE/  # duplicate files are not deleted but put here
NAS_RAW=${NAS_MNT%/}/ORIGINAL/         # for original files (RAW, DNG, JPG, ...)
NAS_SRC=${NAS_MNT%/}/INBOX/            # files are moved from here to their destinations

# regular expressions
# file name part for timestamp, like "yyyymmdd-hhmmss", expecting years 1900-2099
#        |yyyy-------------|mm------|dd-------||hh-------|mm-------|ss-------|
RGX_DAT="[12][09][0-9][0-9][01][0-9][0-3][0-9]-[012][0-9][0-5][0-9][0-6][0-9]"
RGX_DAY="[12][09][0-9][0-9][01][0-9][0-3][0-9]"

# file name extension for archive file and its side-car, like "ext1|ext2"
RGX_ARC="dng|xmp"
# file name extensions for side car files, like "ext1|ext2|..."
RGX_CAR="cos|dop|nks|pp3|.?s.spd"
# file name extensions for edited image files, like "ext1|ext2|..."
RGX_EDT="afphoto|bmp|eps|ico|pdf|psd"
# file name extensions for regular image files, like "ext1|ext2|..."
RGX_IMG="gif|jpeg|jpg|png|tif|tiff"
# file name extensions for RAW image files, like "ext1|ext2|..."
RGX_RAW="3fr|3pr|ari|arw|bay|cap|ce1|ce2|cib|cmt|cr2|craw|crw|dc2|dcr|dcs|eip|erf|exf|fff|fpx|gray|grey|gry|heic|iiq|kc2|kdc|kqp|lfr|mdc|mef|mfw|mos|mrw|ndd|nef|nop|nrw|nwb|olr|orf|pcd|pef|ptx|r3d|ra2|raf|raw|rw2|rwl|rwz|sd[01]|sr2|srf|srw|st[45678]|stx|x3f|ycbcra"


# --- nothing beyond this line needs configuration -----------------------------
for d in "${0%/*}" ~ . ; do source "$d/.antu-photo.cfg" 2>/dev/null || source "$d/antu-photo.cfg" 2>/dev/null; done
source "$LIB_antu_photo"


# === MAIN ===

# Check for NAS directory and wake up the NAS, if needed
if [[ ! -e "$NAS_SRC" ]]; then $CMD_wakeup_nas ; fi
if [[ ! -e "$NAS_SRC" ]]; then exit ; fi
cd "${NAS_SRC%/}"

# Ensure the needed directories are available
[[ -d "${NAS_ARC}" ]] || ( mkdir -p "${NAS_ARC}" && printWarn "Permanently created ${NAS_ARC}" )
[[ -d "${NAS_CAR}" ]] || ( mkdir -p "${NAS_CAR}" && printWarn "Permanently created ${NAS_CAR}" )
[[ -d "${NAS_DUP}" ]] || ( mkdir -p "${NAS_DUP}" && printWarn "Permanently created ${NAS_DUP}" )
[[ -d "${NAS_EDT}" ]] || ( mkdir -p "${NAS_EDT}" && printWarn "Permanently created ${NAS_EDT}" )
[[ -d "${NAS_ERR}" ]] || ( mkdir -p "${NAS_ERR}" && printWarn "Permanently created ${NAS_ERR}" )
[[ -d "${NAS_RAW}" ]] || ( mkdir -p "${NAS_RAW}" && printWarn "Permanently created ${NAS_RAW}" )
[[ -d "${NAS_SRC}" ]] || ( mkdir -p "${NAS_SRC}" && printWarn "Permanently created ${NAS_SRC}" )

printToLog "${0} started"

# I. Find original raw files and move to ORIGINAL/yyyy/yyyy-mm-dd/yyyymmdd-hhmmss[_f].ext
printInfo "I.   Find original raw files and move to ORIGINAL ------------------"

find ${MAC:+-E} . -iregex ".*/${RGX_DAT}(_[0-9][0-9]?)?\.(${RGX_RAW})" -type f -print0 | while IFS= read -r -d $'\0' file; do
	fn="${file##*/}"   # full file name
	bn="${fn%.*}"      # file base name
	ex="${fn##*.}"     # file extension
	yy="${fn:0:4}"     # year
	mm="${fn:4:2}"     # month
	dd="${fn:6:2}"     # day
	ddir="${NAS_RAW%/}/${yy}/${yy}-${mm}-${dd}/" # destination directory
	printInfo "$fn"
	# 1.   If destination exists and has same filename, compare files
	# 1.1.     if identical remove current, keep destination
	# 1.2.     if not identical move current to ERROR
	# 2.   If destination exists and has other filename extension
	# 2.1.     both are RAW, move current to ERROR
	# 2.3.     current is RAW, destination is not, exchange files
	# 3.   If destination does not exist, move current there
	# ---
	# 1.   If destination exists and has same filename, compare files
	if [[ -e "${ddir%/}/${fn}" ]] ; then
		cmp --silent "$file" "${ddir%/}/${fn}"
		if [ $? == 0 ] ; then
			# 1.1. if identical remove current, keep destination
			printToLog "${file} identical with file in ${ddir}, removing it"
			mv --backup=t -f "${file}" "${NAS_DUP%/}/"
		else
			# 1.2. if not identical move current to ERROR
			printToLog "${file} has same filename in ${ddir} but is not identical, moving to ${NAS_ERR%/}"
			mv --backup=t -f "${file}" "${NAS_ERR%/}/"
		fi
	else
		# 2.   If destination exists and has other filename extension
		if compgen -G "${ddir%/}/${bn}.*" ; then
			if test -n "$(find ${MAC:+-E} "${ddir}" -maxdepth 1 -iregex ".*/${bn}\.(${RGX_RAW})" -print -quit)"; then
				# 2.1. both are RAW, move current to ERROR
				printToLog "Another RAW file type of ${file} exists in ${ddir}, moving to ${NAS_ERR%/}"
				mv --backup=t -f "${file}" "${NAS_ERR%/}/"
			else
				# 2.3. current is RAW, destination is not, exchange files
				printToLog "Exchanging ${file} with ${ddir%/}/${bn}*"
				mv --backup=t -f "${ddir%/}/${bn}*" .
				mv "${file}" "${ddir}"
			fi
		else
			# 3.   If destination does not exist, move current there
			printToLog "${file} moved to ${ddir}"
			mkdir -p "${ddir}"
			mv "${file}" "${ddir}"
		fi
	fi
done



# II. Find other original image files and move to ORIGINAL/yyyy/yyyy-mm-dd/yyyymmdd-hhmmss[_f].ext
printInfo "II.  Find other original image files and move to ORIGINAL ----------"

find ${MAC:+-E} . -iregex ".*/${RGX_DAT}(_[0-9][0-9]?)?\.(${RGX_IMG})" -type f -print0 | while IFS= read -r -d $'\0' file; do
	fn="${file##*/}"   # full file name
	bn="${fn%.*}"      # file base name
	ex="${fn##*.}"     # file extension
	yy="${fn:0:4}"     # year
	mm="${fn:4:2}"     # month
	dd="${fn:6:2}"     # day
	ddir="${NAS_RAW%/}/${yy}/${yy}-${mm}-${dd}/" # destination directory
	printInfo "$fn"
	# 1.   If destination exists and has same filename, compare files
	# 1.1. if identical remove current, keep destination
	# 1.2. if not identical move current to ERROR
	# 2.   If destination exists and has other filename extension
	# 2.1. destination is RAW, current is not, do nothing (will be found in next step)
	# 2.2. both are not RAW, move current to ERROR
	# 3.   If destination does not exist, move current there
	# ---
	# 1.   If destination exists and has same filename, compare files
	if [[ -e "${ddir%/}/${fn}" ]] ; then
		cmp --silent "$file" "${ddir%/}/${fn}"
		if [ $? == 0 ] ; then
			# 1.1. if identical remove current, keep destination
			printToLog "${file} identical with file in ${ddir}, removing it"
			mv --backup=t -f "${file}" "${NAS_DUP%/}/"
		else
			# 1.2. if not identical move current to ERROR
			printToLog "${file} has same filename in ${ddir} but is not identical, moving to ${NAS_ERR%/}"
			mv --backup=t -f "${file}" "${NAS_ERR%/}/"
		fi
	else
		# 2.   If destination exists and has other filename extension
		if compgen -G "${ddir%/}/${bn}.*" ; then
			if test -n "$(find ${MAC:+-E} ${ddir%/} -maxdepth 1 -iregex ".*/${bn}\.(${RGX_RAW})" -print -quit)"; then
				# 2.1. destination is RAW, current is not, do nothing (will be found in next step)
				printToLog "A RAW version of ${file} exists in ${ddir}."
			else
				# both are not RAW, move current to ERROR
				printToLog "Another file type of ${file} exists in ${ddir}, moving to ${NAS_ERR%/}"
				mv --backup=t -f "${file}" "${NAS_ERR%/}/"
			fi
		else
			# 3.   If destination does not exist, move current there
			printToLog "${file} moved to ${ddir}"
			mkdir -p "${ddir}"
			mv "${file}" "${ddir}"
		fi
	fi
done



# III. Find other image files and move to EDIT/yyyy/yyyy-mm-dd/yyyymmdd-hhmmss[_f].ext
printInfo "III. Find other image files and move to EDIT  ----------------------"

find ${MAC:+-E} . -iregex ".*/${RGX_DAT}(_[0-9][0-9]?)?\.(${RGX_EDT}|${RGX_IMG})" -type f -print0 | while IFS= read -r -d $'\0' file; do
	fn="${file##*/}"   # full file name
	bn="${fn%.*}"      # file base name
	ex="${fn##*.}"     # file extension
	yy="${fn:0:4}"     # year
	mm="${fn:4:2}"     # month
	dd="${fn:6:2}"     # day
	ddir="${NAS_EDT%/}/${yy}/${yy}-${mm}-${dd}/" # destination directory
	printInfo "$fn"
	# 1.   If destination exists and has same filename, compare files
	# 1.1. if identical remove current, keep destination
	# 1.2. if not identical move current to ERROR
	# 2.   If destination does not exist, move current there
	# ---
	# 1.   If destination exists and has same filename, compare files
	if [[ -e "${ddir%/}/${fn}" ]] ; then
		cmp --silent "$file" "${ddir%/}/${fn}"
		if [ $? == 0 ] ; then
			# 1.1. if identical remove current, keep destination
			printToLog "${file} identical with file in ${ddir}, removing it"
			mv --backup=t -f "${file}" "${NAS_DUP%/}/"
		else
			# 1.2. if not identical move current to ERROR
			printToLog "${file} has same filename in ${ddir} but is not identical, moving to ${NAS_ERR%/}"
			mv --backup=t -f "${file}" "${NAS_ERR%/}/"
		fi
	else
		# 2.   If destination does not exist, move current there
		printToLog "${file} moved to ${ddir}"
		mkdir -p "${ddir}"
		mv "${file}" "${ddir}"
	fi
done



# IV. Find archive files and move to ARCHIV/yyyy/yyyy-mm-dd/yyyymmdd-hhmmss[_f].ext
printInfo "IV.  Find archive files and move to ARCHIV -------------------------"

find ${MAC:+-E} . -iregex ".*/${RGX_DAT}(_[0-9][0-9]?)?\.(${RGX_ARC})" -type f -print0 | while IFS= read -r -d $'\0' file; do
	fn="${file##*/}"   # full file name
	bn="${fn%.*}"      # file base name
	ex="${fn##*.}"     # file extension
	yy="${fn:0:4}"     # year
	mm="${fn:4:2}"     # month
	dd="${fn:6:2}"     # day
	ddir="${NAS_ARC%/}/${yy}/${yy}-${mm}-${dd}/" # destination directory
	printInfo echo "$fn"
	# 1.   If destination exists and has same filename, compare files
	# 1.1. if identical remove current, keep destination
	# 1.2. if not identical move current to ERROR
	# 2.   If destination does not exist, move current there
	# ---
	# 1.   If destination exists and has same filename, compare files
	if [[ -e "${ddir%/}/${fn}" ]] ; then
		cmp --silent "$file" "${ddir%/}/${fn}"
		if [ $? == 0 ] ; then
			# 1.1. if identical remove current, keep destination
			printToLog "${file} identical with file in ${ddir}, removing it"
			mv --backup=t -f "${file}" "${NAS_DUP%/}/"
		else
			# 1.2. if not identical move current to ERROR
			printToLog "${file} has same filename in ${ddir} but is not identical, moving to ${NAS_ERR%/}"
			mv --backup=t -f "${file}" "${NAS_ERR%/}/"
		fi
	else
		# 2.   If destination does not exist, move current there
		printToLog "${file} moved to ${ddir}"
		mkdir -p "${ddir}"
		mv "${file}" "${ddir}"
	fi
done



# V. Find SideCar files and move to EDIT/SideCar/yyyy/yyyy-mm-dd/yyyymmdd-hhmmss[_f].ext

printInfo "V.   Find SideCar files and move to EDIT ---------------------------"

find ${MAC:+-E} . -iregex ".*/(${RGX_DAT}|${RGX_DAY})(_[0-9][0-9]?)?.*\.(${RGX_CAR})" -type f -print0 | while IFS= read -r -d $'\0' file; do
	fn="${file##*/}"   # full file name
	bn="${fn%.*}"      # file base name
	ex="${fn##*.}"     # file extension
	yy="${fn:0:4}"     # year
	mm="${fn:4:2}"     # month
	dd="${fn:6:2}"     # day
	ddir="${NAS_CAR%/}/${yy}/${yy}-${mm}-${dd}/" # destination directory
	printInfo "$fn"
	# 1.   If destination exists and has same filename, compare files (md5?)
	# 1.1. if identical remove current, keep destination
	# 1.2. if not identical move current to ERROR
	# 2.   If destination does not exist, move current there
	# ---
	# 1.   If destination exists and has same filename, compare files
	if [[ -e "${ddir%/}/${fn}" ]] ; then
		cmp --silent "$file" "${ddir%/}/${fn}"
		if [ $? == 0 ] ; then
			# 1.1. if identical remove current, keep destination
			printToLog "${file} identical with file in ${ddir}, removing it"
			mv --backup=t -f "${file}" "${NAS_DUP%/}/"
		else
			# 1.2. if not identical move current to ERROR
			printToLog "${file} has same filename in ${ddir} but is not identical, moving to ${NAS_ERR%/}"
			mv --backup=t -f "${file}" "${NAS_ERR%/}/"
		fi
	else
		# 2.   If destination does not exist, move current there
		printToLog "${file} moved to ${ddir}"
		mkdir -p "${ddir}"
		mv "${file}" "${ddir}"
	fi
done

echo "Files remaining: $(find $NAS_SRC ! -name '.*' -type f | wc -l)"
echo "Files in error : $(find $NAS_ERR ! -name '.*' -type f | wc -l)"

