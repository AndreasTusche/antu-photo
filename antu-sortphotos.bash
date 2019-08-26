#!/bin/bash
#
# NAME
#	antu-sortphotos.bash - move photos and videos to daily folders
#
# SYNOPSIS
#	antu-sortphotos.bash [-2|--stage2]
#
# DESCRIPTION
#	A quick wrapper around the 'exiftool' tool for my preferred directory
#	strucure. It moves
#	* movies        from     ~/Pictures/INBOX/ and subfolders
#	                to       ~/Movies/YYYY/YYYY-MM-DD/
#	* movies        from     ~/Movies/
#	                to       ~/Movies/YYYY/YYYY-MM-DD/
#	* raw images    from     ~/Pictures/INBOX/ and subfolders
#	                to       ~/Pictures/RAW/YYYY/YYYY-MM-DD/
#	* edited images from     ~/Pictures/INBOX/ and subfolders
#	                to       ~/Pictures/edit/YYYY/YYYY-MM-DD/
#	* photos        from     ~/Pictures/INBOX/ and subfolders
#	                to       ~/Pictures/sorted/YYYY/YYYY-MM-DD/
#
#	Above default direcory names may be overwritten by the antu-photo.cfg file.
#
#	Before actually working on the photos, unwanted files - e.g. those
#	'Packages' which are actually directries on Mac OS X - are moved to a
#	separate folder. They are recognised by their file extension:
#		.app .bin .cocatalog .ctg .dmg .icbu .imovielibrary .keynote .oo3 .mpkg
#		.numbers .pages .photoslibrary .pkg .theater .thm .webarchive
#
#	Movies are sorted first. They are recognised by their file extension:
#		.3g2 .3gp .aae .asf .avi .drc .flv .f4v .f4p .f4a .f4b .lrv .m4v .mkv
#		.mov .qt .mp4 .m4p .moi .mod .mpg, .mp2 .mpeg .mpe .mpv .mpg .mpeg .m2v
#		.ogv .ogg .pgi .rm .rmvb .roq .svi .vob .webm .wmv .yuv
#
#	Raw images are recognised by their file extension:
#		.3fr .3pr .ari .arw .bay .cap .ce1 .ce2 .cib .cmt .cr2 .craw .crw .dc2
#		.dcr .dcs .dng .eip .erf .exf .fff .fpx .gray .grey .gry .iiq .kc2 .kdc
#		.kqp .lfr .mdc .mef .mfw .mos .mrw .ndd .nef .nop .nrw .nwb .olr .orf
#		.pcd .pef .ptx .r3d .ra2 .raf .raw .rw2 .rwl .rwz .sd[01] .sr2 .srf .srw
#		.st[45678] .stx .x3f .ycbcra
#
#	Derived or edited images are recognised by their file extension:
#		.afphoto .bmp .eps .pdf .psd .tif .tiff
#
#	All files are checked, if their EXIF timestamps had been corrupted, and are
#	fixed, if necessary. It is expected that all timestamps are either identical
#	or increasing in this order:
# 		CreateDate ≤ DateTimeOriginal ≤ ModifyDate ≤ FileModifyDate
#		≤ FileInodeChangeDate ≤ FileAccessDate
#
#	Images and RAW images are renamed to YYYYMMDD-hhmmss.xxx, based on their
#	CreateDate. If two pictures were taken at the same second, the filename will
#	be suffixed with an incremental sequence number: YYYYMMDD-hhmmss_nn.xxx .
#
#	In a second invocation, with option '--stage2', pictures will be resorted
#	* photos        from     ~/Pictures/sorted/ and subfolders
#	                to       ~/Pictures/YYYY/YYYY-MM-DD/
#
# FILES
#	Uses exiftool (http://www.sno.phy.queensu.ca/~phil/exiftool/)
#
# BUGS
#	- The exiftool may bail out on non-ascii characters in the filename.
#	- Companion files from 3rd party software (sidecar files) are not renamed
#	  and may loose their intended function.
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
# 2015-11-05 AnTu initial version using sortphoto python script
# 2015-12-05 AnTu added --stage2 option
# 2017-04-09 AnTu got rid of python script, now using exiftool directly
# 2018-12-30 AnTu added call to trash-duplicates
# 2019-08-02 AnTu check for pictures (JPG, etc.) wich are the only originals
# 2019-08-24 AnTu have two digit counter for backup-type file names

# default config
export DEBUG=1
export VERBOSE=1

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

# The 2nd stage moves files to their final local destination
MYSTAGE=1
if [[ "$1" == "-2" || "$1" == "--stage2" ]] ; then
	MYSTAGE=2
	DIR_SRC=$DIR_SRC_2
	DIR_PIC=$DIR_PIC_2
fi

# Have local logfile, if NAS was not mounted
if [[ ! -e "$NAS_SRC" ]]; then
	LOGFILE="${DIR_PIC_2%/}/.antu-photo.log"
fi



# === MAIN =====================================================================

printToLog '-------------------------------------------------------------------'
printToLog "${0} started [stage $MYSTAGE]"

cd "${DIR_SRC%/}"

mkdir -p "$DIR_TMP"
mkdir -p "$DIR_ERR"

if [ "$MYSTAGE" == "1" ] ; then
# --- stage 1 only -------------------------------------------------------------

	photo_align_backup_file_names "${DIR_SRC%/}"
	
	# move errornous files out of the way
	printInfo "Check File Types ..."
	(($DEBUG)) && pause 42
	find ${MAC:+-E} . -iregex ".*\.($RGX_ERR)" -exec mv --backup=numbered -f ${DEBUG:+"-v"} "{}" "${DIR_ERR%/}"/ \;
	photo_align_backup_file_names "${DIR_ERR%/}"

	# move and rename video clips amd movies
	printInfo "Movies ..."
	(($DEBUG)) && pause 42
	find ${MAC:+-E} . -iregex ".*\.($RGX_MOV)" -exec mv --backup=numbered -f ${DEBUG:+"-v"} "{}" "${DIR_TMP%/}"/ \;
	photo_align_backup_file_names "${DIR_TMP%/}"
	if [[ $CORRECTTIM == 1 ]] ; then $CMD_correcttim "${DIR_TMP%/}" ; fi
	if [[ $TRASHDUPES == 1 ]] ; then $CMD_trashdupes "${DIR_TMP%/}" "${DIR_MOV%/}" ; fi
	$CMD_sortphotos "${DIR_TMP%/}" "${DIR_MOV%/}"

	# then move and rename RAW and archive files
	# @ToDo: Sidecar files .cos .dop .nks .pp3 .?s.spd .xmp
	printInfo "RAW ..."
	(($DEBUG)) && pause 42
	find -E . -iregex ".*\.($RGX_RAW|$RGX_ARC)" -exec mv --backup=numbered -f ${DEBUG:+"-v"} "{}" "${DIR_TMP%/}"/ \;
	photo_align_backup_file_names "${DIR_TMP%/}"
	if [[ $CORRECTTIM == 1 ]] ; then $CMD_correcttim "${DIR_TMP%/}" ; fi
	if [[ $TRASHDUPES == 1 ]] ; then $CMD_trashdupes "${DIR_TMP%/}" "${DIR_RAW%/}" ; fi
	$CMD_sortphotos "${DIR_TMP%/}" "${DIR_RAW%/}"

	# then move and rename edited files
	# @ToDo: Sidecar files .cos .dop .nks .pp3 .?s.spd .xmp
	printInfo "EDIT ..."
	(($DEBUG)) && pause 42
	find ${MAC:+-E} . -iregex ".*\.($RGX_EDT)" -exec mv --backup=numbered -f ${DEBUG:+"-v"} "{}" "${DIR_TMP%/}"/ \;
	photo_align_backup_file_names "${DIR_TMP%/}"
	if [[ $CORRECTTIM == 1 ]] ; then $CMD_correcttim "${DIR_TMP%/}" ; fi
	if [[ $TRASHDUPES == 1 ]] ; then $CMD_trashdupes "${DIR_TMP%/}" "${DIR_EDT%/}" ; fi
	$CMD_sortphotos "${DIR_TMP%/}" "${DIR_EDT%/}"
	
fi # [ "$MYSTAGE" == "1" ]



# --- stage 1 and 2 ------------------------------------------------------------

# move and rename all remaining picture files
printInfo "Pictures ..."
(($DEBUG)) && pause 42
find ${MAC:+-E} . -iregex ".*\.($RGX_IMG)" -not -path "${DIR_TMP%/}/*" -exec mv --backup=numbered -f ${DEBUG:+"-v"} "{}" "${DIR_TMP%/}"/ \;
photo_align_backup_file_names "${DIR_TMP%/}"
if [[ $CORRECTTIM == 1 ]] ; then $CMD_correcttim "${DIR_TMP%/}" ; fi
if [[ $TRASHDUPES == 1 ]] ; then $CMD_trashdupes "${DIR_TMP%/}" "${DIR_PIC%/}" ; fi
$CMD_sortphotos "${DIR_TMP%/}" "${DIR_PIC%/}"



if [ "$MYSTAGE" == "1" ] ; then
# --- stage 1 only -------------------------------------------------------------

	printInfo "searching for pictures which are actually also originals ..."

	# I. Find original raw files and copy to RAW/yyyy/yyyy-mm-dd/yyyymmdd-hhmmss[_ff].ext
	printInfo "... find original raw files and copy to RAW"
	(($DEBUG)) && pause 42

	find ${MAC:+-E} "${DIR_PIC%/}" -iregex ".*/${RGX_DAT}(_[0-9][0-9]?)?\.(${RGX_RAW})" -type f -print0 | while IFS= read -r -d $'\0' file; do
		#  "${file}"       # file name with path                   /path1/path2/20170320-065042_01.jpg.dop.~3~
		dn="${file%/*}"    # directory name                        /path1/path2
		fn="${file##*/}"   # full file name                        20170320-065042_01.jpg.dop.~3~
		n0="${file##*.}"   # full numbering                        ~3~
		n1="${n0//\~/}"    # numbering                             3
		b0="${fn%%.~*}"    # file name without numbering           20170320-065042_01.jpg.dop
		ex="${b0#*.}"      # extension(s)                          jpg.dop
		b1="${b0%%.*}"     # file base name (w/o extension(s))     20170320-065042_01
		bn="${b1%%_*}"     # file base name (w/o sequence number)  20170320-065042
		sq="${b1#*_}"      # sequence number                       01
		yy="${fn:0:4}"     # year                                  2017
		mm="${fn:4:2}"     # month                                 03
		dd="${fn:6:2}"     # day                                   20
		ddir="${DIR_RAW%/}/${yy}/${yy}-${mm}-${dd}/" # destination directory
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
				printToLog "${fn} identical with file in ${ddir}, removing it"
				mv --backup=t -f "${file}" "${DIR_RCY%/}/"
			else
				# 1.2. if not identical move current to ERROR
				printToLog "${fn} has same filename in ${ddir} but is not identical, moving to ${DIR_ERR%/}"
				mv --backup=t -f "${file}" "${DIR_ERR%/}/"
			fi
		else
			# 2.   If destination exists and has other filename extension
			if compgen -G "${ddir%/}/${bn}.*" ; then
				if test -n "$(find ${MAC:+-E} "${ddir}" -maxdepth 1 -iregex ".*/${bn}\.(${RGX_RAW})" -print -quit)"; then
					# 2.1. both are RAW, move current to ERROR
					printToLog "Another RAW file type of ${fn} exists in ${ddir}, moving to ${DIR_ERR%/}"
					mv --backup=t -f "${file}" "${DIR_ERR%/}/"
				else
					# 2.3. current is RAW, destination is not, exchange files
					printToLog "Exchanging ${file} with ${ddir%/}/${bn}*"
					mv --backup=t -f "${ddir%/}/${bn}*" .
					mv "${file}" "${ddir}"
				fi
			else
				# 3.   If destination does not exist, copy current there
				printToLog "${file} copied to ${ddir}"
				mkdir -p "${ddir}"
				cp "${file}" "${ddir}"
			fi
		fi
	done



	# II. Find other original image files and move to RAW/yyyy/yyyy-mm-dd/yyyymmdd-hhmmss[_ff].ext
	printInfo "... find other original image files and copy to RAW"
	(($DEBUG)) && pause 42

	find ${MAC:+-E} "${DIR_PIC%/}" -iregex ".*/${RGX_DAT}(_[0-9][0-9]?)?\.(${RGX_IMG})" -type f -print0 | while IFS= read -r -d $'\0' file; do
		#  "${file}"       # file name with path                   /path1/path2/20170320-065042_01.jpg.dop.~3~
		dn="${file%/*}"    # directory name                        /path1/path2
		fn="${file##*/}"   # full file name                        20170320-065042_01.jpg.dop.~3~
		n0="${file##*.}"   # full numbering                        ~3~
		n1="${n0//\~/}"    # numbering                             3
		b0="${fn%%.~*}"    # file name without numbering           20170320-065042_01.jpg.dop
		ex="${b0#*.}"      # extension(s)                          jpg.dop
		b1="${b0%%.*}"     # file base name (w/o extension(s))     20170320-065042_01
		bn="${b1%%_*}"     # file base name (w/o sequence number)  20170320-065042
		sq="${b1#*_}"      # sequence number                       01
		yy="${fn:0:4}"     # year                                  2017
		mm="${fn:4:2}"     # month                                 03
		dd="${fn:6:2}"     # day                                   20
		ddir="${DIR_RAW%/}/${yy}/${yy}-${mm}-${dd}/" # destination directory
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
				printToLog "${fn} identical with file in ${ddir}, removing it"
				mv --backup=t -f "${file}" "${DIR_RCY%/}/"
			else
				# 1.2. if not identical move current to ERROR
				printToLog "${fn} has same filename in ${ddir} but is not identical, moving to ${DIR_ERR%/}"
				mv --backup=t -f "${file}" "${DIR_ERR%/}/"
			fi
		else
			# 2.   If destination exists and has other filename extension
			if compgen -G "${ddir%/}/${b1}.*" ; then
				if test -n "$(find ${MAC:+-E} ${ddir%/} -maxdepth 1 -iregex ".*/${b1}\.(${RGX_RAW})" -print -quit)"; then
					# 2.1. destination is RAW, current is not, do nothing (will be found in next step)
					printToLog "A RAW version of ${fn} exists in ${ddir}. (nothing done)"
				else
					# both are not RAW, move current to ERROR
					printToLog "Another file type of ${fn} exists in ${ddir}, moving to ${DIR_ERR%/}"
					mv --backup=t -f "${file}" "${DIR_ERR%/}/"
				fi
			else
				# 3.   If destination does not exist, copy current there but keep a copy for the next step
				printToLog "${file} copied to ${ddir}"
				mkdir -p "${ddir}"
				cp "${file}" "${ddir}"
			fi
		fi
	done



	# III. Find other image files and move to EDIT/yyyy/yyyy-mm-dd/yyyymmdd-hhmmss[_ff].ext
	printInfo "... find other image files and move to EDIT"
	(($DEBUG)) && pause 42

	find ${MAC:+-E} "${DIR_PIC%/}" -iregex ".*/${RGX_DAT}(_[0-9][0-9]?)?\.(${RGX_EDT})" -type f -print0 | while IFS= read -r -d $'\0' file; do
		#  "${file}"       # file name with path                   /path1/path2/20170320-065042_01.jpg.dop.~3~
		dn="${file%/*}"    # directory name                        /path1/path2
		fn="${file##*/}"   # full file name                        20170320-065042_01.jpg.dop.~3~
		n0="${file##*.}"   # full numbering                        ~3~
		n1="${n0//\~/}"    # numbering                             3
		b0="${fn%%.~*}"    # file name without numbering           20170320-065042_01.jpg.dop
		ex="${b0#*.}"      # extension(s)                          jpg.dop
		b1="${b0%%.*}"     # file base name (w/o extension(s))     20170320-065042_01
		bn="${b1%%_*}"     # file base name (w/o sequence number)  20170320-065042
		sq="${b1#*_}"      # sequence number                       01
		yy="${fn:0:4}"     # year                                  2017
		mm="${fn:4:2}"     # month                                 03
		dd="${fn:6:2}"     # day                                   20
		ddir="${DIR_EDT%/}/${yy}/${yy}-${mm}-${dd}/" # destination directory
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
				printToLog "${fn} identical with file in ${ddir}, removing it"
				mv --backup=t -f "${file}" "${DIR_RCY%/}/"
			else
				# 1.2. if not identical move current to ERROR
				printToLog "${fn} has same filename in ${ddir} but is not identical, moving to ${DIR_ERR%/}"
				mv --backup=t -f "${file}" "${DIR_ERR%/}/"
			fi
		else
			# 2.   If destination does not exist, move current there
			printToLog "${file} moved to ${ddir}"
			mkdir -p "${ddir}"
			mv "${file}" "${ddir}"
		fi
	done
	
	# Note: on stage 1, skipping step IV (archive files)
	printInfo "... skipping Archive files"

	# V. Find SideCar files and move to RAW/yyyy/yyyy-mm-dd/yyyymmdd-hhmmss[_ff].ext

	printInfo "... find SideCar files and move to RAW"
	(($DEBUG)) && pause 42

	find ${MAC:+-E} "${DIR_PIC%/}" -iregex ".*/(${RGX_DAT}|${RGX_DAY})(_[0-9][0-9]?)?.*\.(${RGX_CAR})" -type f -print0 | while IFS= read -r -d $'\0' file; do
		#  "${file}"       # file name with path                   /path1/path2/20170320-065042_01.jpg.dop.~3~
		dn="${file%/*}"    # directory name                        /path1/path2
		fn="${file##*/}"   # full file name                        20170320-065042_01.jpg.dop.~3~
		n0="${file##*.}"   # full numbering                        ~3~
		n1="${n0//\~/}"    # numbering                             3
		b0="${fn%%.~*}"    # file name without numbering           20170320-065042_01.jpg.dop
		ex="${b0#*.}"      # extension(s)                          jpg.dop
		b1="${b0%%.*}"     # file base name (w/o extension(s))     20170320-065042_01
		bn="${b1%%_*}"     # file base name (w/o sequence number)  20170320-065042
		sq="${b1#*_}"      # sequence number                       01
		yy="${fn:0:4}"     # year                                  2017
		mm="${fn:4:2}"     # month                                 03
		dd="${fn:6:2}"     # day                                   20
		ddir="${DIR_RAW%/}/${yy}/${yy}-${mm}-${dd}/" # destination directory
		echo "$fn"
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
				printToLog "${fn} identical with file in ${ddir}, removing it"
				mv --backup=t -f "${file}" "${DIR_RCY%/}/"
			else
				# 1.2. if not identical move current to ERROR
				printToLog "${fn} has same filename in ${ddir} but is not identical, moving to ${DIR_ERR%/}"
				mv --backup=t -f "${file}" "${DIR_ERR%/}/"
			fi
		else
			# 2.   If destination does not exist, move current there
			printToLog "${file} moved to ${ddir}"
			mkdir -p "${ddir}"
			mv "${file}" "${ddir}"
		fi
	done

fi # [ "$MYSTAGE" == "1" ]





# if [ "$1" != "--stage2" ] ; then
#  echo "... extracting GPS coordinates"
#  # assuming we have pictures from after the year 2000
#  for d in ${DIR_PIC%/}/2*; do
#   for dd in "${d%/}"/2*; do
#    if [[ ! -e "${dd%/}/${GPS_LOG}" ]]; then
#        $CMD_extractgps "${dd}"  >"${dd%/}/${GPS_LOG}"
#     if [[ ! -s "${dd%/}/${GPS_LOG}" ]]; then
#      rm "${dd%/}/${GPS_LOG}"
#     fi
#    fi
#   done
#  done
# fi

## one-liner for manual gps extract:
# for d in ~/Pictures/2*; do for dd in "${d%/}"/2*; do if [[ ! -e "${dd%/}/gps.gpx" ]]; then ~/Develop/antu-photo/photo-extract-gps.bash "${dd}" >"${dd%/}/gps.gpx"; fi; done; done

# finally clean up
rm -f "$DIR_TMP/.DS_Store"
rm -d "$DIR_TMP"
printInfo "=== done"
