#!/bin/bash
#
# NAME
#	photo-nas-sort.bash - sort original photos from NAS INBOX to folders
#
# SYNOPSIS
#	photo-nas-sort.bash
#
# DESCRIPTION
#	This script is to be run on main computer which has the NAS mounted,
#	not to be run on the NAS itself.
#
#	Photos are expected to already have final desired filenames, e.g.
# 		YYYYMMDD-hhmmss[_ff].xxx
#	and are located in the NAS::Pictures/INBOX folder.
#
#	This script moves
# 	* original images from     NAS::Pictures/INBOX/ and subfolders
#                     to       NAS::Pictures/ORIGINAL/YYYY/YYYY-MM-DD/
# 	* derived images  from     NAS::Pictures/INBOX/ and subfolders
#                     to       NAS::Pictures/EDIT/YYYY/YYYY-MM-DD/
#	* created DNG     from     NAS::Pictures/INBOX/ and subfolders
#                     to       NAS::Pictures/ARCHIV/YYYY/YYYY-MM-DD/
#
#	Above direcories names may be overwritten by the antu-photo.cfg file.
#
# FILES
#	antu-photo.cfg - configuration file
#
# BUGS
#   - Companion files from 3rd party software are not renamed and may loose
#     their intended function.
# @ToDo compare filenames only for timestamps not sequence numbers, see also trash-duplicates.
# @ToDo if new sequence numbers are needed then use two digits
#	- to be run on main computer which has NAS mounted, not on NAS itself
#
# AUTHOR
#	@author     Andreas Tusche    <antu-photo@andreas-tusche.de>
#	@copyright  (c) 2018-2019, Andreas Tusche <www.andreas-tusche.de>
#	@package    antu-photo
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# when       who  what
# ---------- ---- --------------------------------------------------------------
# 2018-12-30 AnTu created

# default config
export DEBUG=1
export VERBOSE=1

# --- nothing beyond this line needs configuration -----------------------------
if [ "$ANTU_PHOTO_CFG_DONE" != "1" ] ; then # read the configuration file(s)
	for d in "${0%/*}" ~ . ; do source "$d/.antu-photo.cfg" 2>/dev/null || source "$d/antu-photo.cfg" 2>/dev/null; done
fi
(($PHOTO_LIB_DONE)) || source "$LIB_antu_photo"



# === MAIN =====================================================================

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
[[ -d "${NAS_ORG}" ]] || ( mkdir -p "${NAS_ORG}" && printWarn "Permanently created ${NAS_ORG}" )
[[ -d "${NAS_SRC}" ]] || ( mkdir -p "${NAS_SRC}" && printWarn "Permanently created ${NAS_SRC}" )

printToLog "${0} started"

#echo "Files to sort  : $(find ${NAS_SRC%/} ! -name '.*' -type f)"
echo "Files to sort  : $(find ${NAS_SRC%/} ! -name '.*' -type f | wc -l)"

# Rename backup-style filenames, if any
for f in *.~*; do
	if [[ -e $f ]]; then
		n=${f%~*}
		e=${f#*.}
		mv -n ${DEBUG:+"-v"} "${f}" "${f%%.*}_${n#*~}.${e%.*}"
	fi
done

# convert single digit sequence numbers to two digit
for f in *_[0-9].*; do
	if [[ -e $f ]]; then
		mv -n ${DEBUG:+"-v"} "${f}" "${f%_*}_0${f#*_}"
	fi
done



# I. Find original raw files and move to ORIGINAL/yyyy/yyyy-mm-dd/yyyymmdd-hhmmss[_ff].ext
printInfo "I.   Find original raw files and move to ORIGINAL ------------------"

find ${MAC:+-E} . -iregex ".*/${RGX_DSQ}\.(${RGX_RAW})" -type f -print0 | while IFS= read -r -d $'\0' file; do
	#  "${file}"       # file name with path                   /path1/path2/20170320-065042_01.jpg.~3~
	dn="${file%/*}"    # directory name                        /path1/path2
	fn="${file##*/}"   # full file name                        20170320-065042_01.jpg.~3~
	b0="${fn%%.~*}"    # file name without numbering           20170320-065042_01.jpg
	ex="${b0##*.}"     # extension                             jpg
	b1="${b0%%.*}"     # file base name (w/o extension)        20170320-065042_01
	bn="${b1%%_*}"     # file base name (w/o sequence number)  20170320-065042
	sq="${b1#*_}"      # sequence number                       01
	yy="${fn:0:4}"     # year                                  2017
	mm="${fn:4:2}"     # month                                 03
	dd="${fn:6:2}"     # day                                   20
	ddir="${NAS_ORG%/}/${yy}/${yy}-${mm}-${dd}/" # destination directory
	printInfo "$fn"
	# 1.   If destination exists and has same filename, compare files
	# 1.1.     if identical remove current, keep destination
	# 1.2.     if not identical move current to ERROR
	# 2.   If destination exists and has other filename extension
	# 2.1.     both are RAW, move current to ERROR
	# 2.2.     current is RAW, destination is not, exchange files
	# 3.   If destination exists and has other sequence number
	# 3.1.     if identical remove current, keep destination
	# 3.2.     as destination does not exist, move current there
	# 4.   If destination does not exist, move current there
	# ---
	# 1.   If destination exists and has same filename, compare files
	if [[ -e "${ddir%/}/${b0}" ]] ; then
		cmp --silent "$file" "${ddir%/}/${b0}"
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
		if compgen -G "${ddir%/}/${b1}.*" ; then
			if test -n "$(find ${MAC:+-E} "${ddir}" -maxdepth 1 -iregex ".*/${b1}\.(${RGX_RAW})" -print -quit)"; then
				# 2.1. both are RAW, move current to ERROR
				printToLog "Another RAW file type of ${file} exists in ${ddir}, moving to ${NAS_ERR%/}"
				mv --backup=t -f "${file}" "${NAS_ERR%/}/"
			else
				# 2.2. current is RAW, destination is not, exchange files
				printToLog "Exchanging ${file} with ${ddir%/}/${b1}.*"
				mv --backup=t -f "${ddir%/}/${b1}.*" .
				mv "${file}" "${ddir}"
			fi
		else
			# 3.   If destination exists and has no or another sequence number
			if compgen -G "${ddir%/}/${bn}*" ; then
				for ff in "${ddir%/}/${bn}*" ; do
					cmp --silent "$file" "${ff}"
					if [ $? == 0 ] ; then
						# 3.1. if identical remove current, keep destination
						printToLog "${file} identical with ${ff}, removing it"
						mv --backup=t -f "${file}" "${NAS_DUP%/}/"
						break
					fi
				done
				# 3.2. as destination does not exist, move current there
				if [[ -e ${file} ]]; then
					mv -n ${DEBUG:+"-v"} "${file}" "${ddir}"
					printToLog "${file} moved to ${ddir}"
				fi
			else
				# 4.   If destination does not exist, move current there
				mkdir -p "${ddir}"
				mv -n ${DEBUG:+"-v"} "${file}" "${ddir}"
				printToLog "${file} moved to ${ddir}"
			fi
		fi
	fi
done



# II. Find other original image files and move to ORIGINAL/yyyy/yyyy-mm-dd/yyyymmdd-hhmmss[_ff].ext
printInfo "II.  Find other original image files and move to ORIGINAL ----------"

find ${MAC:+-E} . -iregex ".*/${RGX_DSQ}\.(${RGX_IMG})" -type f -print0 | while IFS= read -r -d $'\0' file; do
	#  "${file}"       # file name with path                   /path1/path2/20170320-065042_01.jpg.~3~
	dn="${file%/*}"    # directory name                        /path1/path2
	fn="${file##*/}"   # full file name                        20170320-065042_01.jpg.~3~
	b0="${fn%%.~*}"    # file name without numbering           20170320-065042_01.jpg
	ex="${b0##*.}"     # extension                             jpg
	b1="${b0%%.*}"     # file base name (w/o extension)        20170320-065042_01
	bn="${b1%%_*}"     # file base name (w/o sequence number)  20170320-065042
	sq="${b1#*_}"      # sequence number                       01
	yy="${fn:0:4}"     # year                                  2017
	mm="${fn:4:2}"     # month                                 03
	dd="${fn:6:2}"     # day                                   20
	ddir="${NAS_ORG%/}/${yy}/${yy}-${mm}-${dd}/" # destination directory
	printInfo "$fn"
	# 1.   If destination exists and has same filename, compare files
	# 1.1.     if identical remove current, keep destination
	# 1.2.     if not identical move current to ERROR
	# 2.   If destination exists and has other filename extension
	# 2.1.     destination is RAW, current is not, do nothing (will be found in next step)
	# 2.2.     both are not RAW, move current to ERROR
	# 3.   If destination exists and has other sequence number
	# 3.1.    if identical remove current, keep destination
	# 3.2.    as destination does not exist, move current there
	# 4.   If destination does not exist, move current there
	# ---
	# 1.   If destination exists and has same filename, compare files
	if [[ -e "${ddir%/}/${b0}" ]] ; then
		cmp --silent "$file" "${ddir%/}/${b0}"
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
		if compgen -G "${ddir%/}/${b1}.*" ; then
			if test -n "$(find ${MAC:+-E} ${ddir%/} -maxdepth 1 -iregex ".*/${b1}\.(${RGX_RAW})" -print -quit)"; then
				# 2.1. destination is RAW, current is not, do nothing (will be found in next step)
				printToLog "A RAW version of ${file} exists in ${ddir}."
			else
				# 2.2 both are not RAW, move current to ERROR
				printToLog "Another file type of ${file} exists in ${ddir}, moving to ${NAS_ERR%/}"
				mv --backup=t -f "${file}" "${NAS_ERR%/}/"
			fi
		else
			# 3.   If destination exists and has no or another sequence number
			if compgen -G "${ddir%/}/${bn}*" ; then
				for ff in "${ddir%/}/${bn}*" ; do
					cmp --silent "$file" "${ff}"
					if [ $? == 0 ] ; then
						# 3.1. if identical remove current, keep destination
						printToLog "${file} identical with ${ff}, removing it"
						mv --backup=t -f "${file}" "${NAS_DUP%/}/"
						break
					fi
				done
				# 3.2. as destination does not exist, move current there
				if [[ -e ${file} ]]; then
					mv -n ${DEBUG:+"-v"} "${file}" "${ddir}"
					printToLog "${file} moved to ${ddir}"
				fi
			else
				# 4.   If destination does not exist, move current there
				printToLog "${file} moved to ${ddir}"
				mkdir -p "${ddir}"
				mv "${file}" "${ddir}"
			fi
		fi
	fi
done



# III. Find other image files and move to EDIT/yyyy/yyyy-mm-dd/yyyymmdd-hhmmss[_ff].ext
printInfo "III. Find other image files and move to EDIT  ----------------------"

find ${MAC:+-E} . -iregex ".*/${RGX_DSQ}\.(${RGX_EDT}|${RGX_IMG})" -type f -print0 | while IFS= read -r -d $'\0' file; do
	#  "${file}"       # file name with path                   /path1/path2/20170320-065042_01.jpg.~3~
	dn="${file%/*}"    # directory name                        /path1/path2
	fn="${file##*/}"   # full file name                        20170320-065042_01.jpg.~3~
	b0="${fn%%.~*}"    # file name without numbering           20170320-065042_01.jpg
	ex="${b0##*.}"     # extension                             jpg
	b1="${b0%%.*}"     # file base name (w/o extension)        20170320-065042_01
	bn="${b1%%_*}"     # file base name (w/o sequence number)  20170320-065042
	sq="${b1#*_}"      # sequence number                       01
	yy="${fn:0:4}"     # year                                  2017
	mm="${fn:4:2}"     # month                                 03
	dd="${fn:6:2}"     # day                                   20
	ddir="${NAS_EDT%/}/${yy}/${yy}-${mm}-${dd}/" # destination directory
	printInfo "$fn"
	# 1.   If destination exists and has same filename, compare files
	# 1.1.     if identical remove current, keep destination
	# 1.2.     if not identical move current to ERROR
	# 2.   If destination exists and has other sequence number
	# 2.1.     if identical remove current, keep destination
	# 2.2.     as destination does not exist, move current there
	# 3.   If destination does not exist, move current there
	# ---
	# 1.   If destination exists and has same filename, compare files
	if [[ -e "${ddir%/}/${b0}" ]] ; then
		cmp --silent "$file" "${ddir%/}/${b0}"
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
		# 2.   If destination exists but has no or another sequence number
		if compgen -G "${ddir%/}/${bn}*" ; then
			for ff in "${ddir%/}/${bn}*" ; do
				cmp --silent "$file" "${ff}"
				if [ $? == 0 ] ; then
					# 2.1. if identical remove current, keep destination
					printToLog "${file} identical with ${ff}, removing it"
					mv --backup=t -f "${file}" "${NAS_DUP%/}/"
					break
				fi
			done
			# 2.2. as destination does not exist, move current there
			if [[ -e ${file} ]]; then
				mv -n ${DEBUG:+"-v"} "${file}" "${ddir}"
				printToLog "${file} moved to ${ddir}"
			fi
		else
			# 3.   If destination does not exist, move current there
			printToLog "${file} moved to ${ddir}"
			mkdir -p "${ddir}"
			mv "${file}" "${ddir}"
		fi
	fi
done



# IV. Find archive files and move to ARCHIV/yyyy/yyyy-mm-dd/yyyymmdd-hhmmss[_ff].ext
printInfo "IV.  Find archive files and move to ARCHIV -------------------------"

find ${MAC:+-E} . -iregex ".*/${RGX_DSQ}\.(${RGX_ARC})" -type f -print0 | while IFS= read -r -d $'\0' file; do
	#  "${file}"       # file name with path                   /path1/path2/20170320-065042_01.jpg.~3~
	dn="${file%/*}"    # directory name                        /path1/path2
	fn="${file##*/}"   # full file name                        20170320-065042_01.jpg.~3~
	b0="${fn%%.~*}"    # file name without numbering           20170320-065042_01.jpg
	ex="${b0##*.}"     # extension                             jpg
	b1="${b0%%.*}"     # file base name (w/o extension)        20170320-065042_01
	bn="${b1%%_*}"     # file base name (w/o sequence number)  20170320-065042
	sq="${b1#*_}"      # sequence number                       01
	yy="${fn:0:4}"     # year                                  2017
	mm="${fn:4:2}"     # month                                 03
	dd="${fn:6:2}"     # day                                   20
	ddir="${NAS_ARC%/}/${yy}/${yy}-${mm}-${dd}/" # destination directory
	printInfo echo "$fn"
	# 1.   If destination exists and has same filename, compare files
	# 1.1. if identical remove current, keep destination
	# 1.2. if not identical move current to ERROR
	# 2.   If destination does not exist, move current there
	# ---
	# 1.   If destination exists and has same filename, compare files
	if [[ -e "${ddir%/}/${b0}" ]] ; then
		cmp --silent "$file" "${ddir%/}/${b0}"
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



# V. Find SideCar files and move to EDIT/SideCar/yyyy/yyyy-mm-dd/yyyymmdd-hhmmss[_ff].ext

printInfo "V.   Find SideCar files and move to EDIT ---------------------------"

find ${MAC:+-E} . -iregex ".*/(${RGX_DAT}|${RGX_DAY})${RGX_SEQ}.*\.(${RGX_CAR})" -type f -print0 | while IFS= read -r -d $'\0' file; do
	#  "${file}"       # file name with path                   /path1/path2/20170320-065042_01.jpg.dop.~3~
	dn="${file%/*}"    # directory name                        /path1/path2
	fn="${file##*/}"   # full file name                        20170320-065042_01.jpg.dop.~3~
	b0="${fn%%.~*}"    # file name without numbering           20170320-065042_01.jpg.dop
	ex="${b0##*.}"     # extension                             dop
	b1="${b0%%.*}"     # file base name (w/o extension)        20170320-065042_01
	bn="${b1%%_*}"     # file base name (w/o sequence number)  20170320-065042
	sq="${b1#*_}"      # sequence number                       01
	yy="${fn:0:4}"     # year                                  2017
	mm="${fn:4:2}"     # month                                 03
	dd="${fn:6:2}"     # day                                   20
	ddir="${NAS_CAR%/}/${yy}/${yy}-${mm}-${dd}/" # destination directory
	printInfo "$fn"
	# 1.   If destination exists and has same filename, compare files (md5?)
	# 1.1. if identical remove current, keep destination
	# 1.2. if not identical move current to ERROR
	# 2.   If destination does not exist, move current there
	# ---
	# 1.   If destination exists and has same filename, compare files
	if [[ -e "${ddir%/}/${b0}" ]] ; then
		cmp --silent "$file" "${ddir%/}/${b0}"
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



# final report
n=$(find $NAS_SRC ! -name '.*' -type f | wc -l)
if [[ $n > 0 ]] ; then 
	printInfo  "Files remaining: $n"
fi

n=$(find $NAS_DUP ! -name '.*' -type f | wc -l)
if [[ $n > 0 ]] ; then 
	printWarn  "Files duplicate: $n"
fi

n=$(find $NAS_ERR ! -name '.*' -type f | wc -l)
if [[ $n > 0 ]] ; then 
	printError "Files in error : $n"
fi

printDebug "-- done"

