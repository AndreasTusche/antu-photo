#!/usr/bin/env bash
# -*- mode: bash; tab-width: 4 -*-
################################################################################
# NAME
#	antu-sortphotos.bash - move photos and videos to daily folders
#
# SYNOPSIS
#	antu-sortphotos.bash [-2|--stage2]
#
# DESCRIPTION
#	A quick wrapper around the 'exiftool' tool for my preferred directory
#	strucure. Everything starts with the INBOX. It moves, in this order:
#	- movies        from     ~/Pictures/INBOX/ and subfolders
#	                to       ~/Movies/YYYY/YYYY-MM-DD/
#	- movies        from     ~/Movies/
#	                to       ~/Movies/YYYY/YYYY-MM-DD/
#	- raw images    from     ~/Pictures/INBOX/ and subfolders
#	                to       ~/Pictures/RAW/YYYY/YYYY-MM-DD/
#	- edited images from     ~/Pictures/INBOX/ and subfolders
#	                to       ~/Pictures/edit/YYYY/YYYY-MM-DD/
#	- photos        from     ~/Pictures/INBOX/ and subfolders
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
#	- photos        from     ~/Pictures/sorted/ and subfolders
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
#	@copyright  (c) 2017-2021, Andreas Tusche <www.andreas-tusche.de>
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

################################################################################
# config
################################################################################

#-------------------------------------------------------------------------------
# Global shell behaviour
#-------------------------------------------------------------------------------

DEBUG=${DEBUG-''}						# 0: do not 1: do print debug messages
                                        # 2: bash verbose, 3: bash xtrace
										# 9: bash noexec

set -o nounset                          # Used variables MUST be initialized.
set -o errtrace                         # Traces error in function & co.
set -o functrace                        # Traps inherited by functions
set -o pipefail                         # Exit on errors in pipe
set +o posix                            # disable POSIX

((DEBUG==0)) && DEBUG=
((DEBUG>1)) && set -o verbose; ((DEBUG<2)) && set +o verbose
((DEBUG>2)) && set -o xtrace;  ((DEBUG<3)) && set +o xtrace
((DEBUG>8)) && set -o noexec;  ((DEBUG<9)) && set +o noexec

((DEBUG)) && VERBOSE=1 || VERBOSE=${VERBOSE:-$DEBUG}
((DEBUG)) && clear && banner -w 32 $(date +%T)

# preliminary functions, may be replaced by those from lib_common.bash
die()        { err=${1-1}; shift; [ -z ${1+x} ] || printError "OLD $@"; exit $err ; }
printDebug() { ((DEBUG)) && echo -e "$(date +'%F %T') \033[1;35mDEBUG  :\033[0;35m ${@}\033[0m" ; }
printError() {              echo -e "$(date +'%F %T') \033[1;91mERROR  :\033[0;91m ${@}\033[0m" ; }
if ! command -v realpath &>/dev/null ; then realpath() { readlink -- "$1" ; } ; fi

#-------------------------------------------------------------------------------
# path to this script - needs GNU `realpath` installed
#-------------------------------------------------------------------------------

#@Todo: Use source lib_coreutils.bash only during development
#@Todo: else photo_check_dependencies() adds coreutils to the PATH
source "$( dirname $( realpath "${BASH_SOURCE[0]}" ) )/lib_coreutils.bash" || die 53 "Library lib_coreutils.bash was not found."

readonly _THIS_SCRIPT="$( realpath "${BASH_SOURCE[0]}" )"
readonly _THIS=$( basename "$_THIS_SCRIPT" )
readonly _THIS_DIR="$( dirname $_THIS_SCRIPT )"

printDebug "_THIS_SCRIPT  = $_THIS_SCRIPT"
printDebug "_THIS         = $_THIS"
printDebug "_THIS_DIR     = $_THIS_DIR"



#-------------------------------------------------------------------------------
# load some function libraries
#-------------------------------------------------------------------------------

source "$_THIS_DIR/lib_common.bash" && ((common_lib_loaded)) || die 53 "Library lib_common.bash was not found."
source "$_THIS_DIR/lib_exif.bash"   && ((exif_lib_loaded))   || die 53 "Library lib_exif.bash was not found."
source "$_THIS_DIR/lib_photo.bash"  && ((photo_lib_loaded))  || die 53 "Library lib_photo.bash was not found."



#-------------------------------------------------------------------------------
# load config file(s), last one found overwrites all the previous ones
#-------------------------------------------------------------------------------

for d in "$_THIS_DIR" ~/.config/antu-photo ~ . ; do
	source "$d/.antu-photo.cfg" 2>/dev/null || \
	source "$d/antu-photo.cfg"  2>/dev/null
done
((ANTU_PHOTO_CFG_LOADED)) || die 51 "No config file antu-photo.cfg found"

photo_config_commands
photo_config_directories_wrk
photo_config_directories_nas
photo_config_directories_rmt



#-------------------------------------------------------------------------------
# check directories
#-------------------------------------------------------------------------------

# If NAS was not mounted, then use a local logfile
photo_NASisMounted || LOGFILE="${DIR_PIC%/}/.antu-photo.log"

photo_check_dependencies #ToDo: also sets PATH to GNU coreutils
photo_check_directories
photo_check_files

((ROTATE_LOGFILE)) && rotateLog $LOGFILE $ROTATE_LOGFILE



################################################################################
# MAIN
################################################################################


printToLog '-------------------------------------------------------------------'
printToLog "$_THIS started by ${USER:-${USERNAME:-${LOGNAME}}}"

((CREATE_MISSING_DIRECTORIES)) && photo_create_directories

# --- stage 1 ------------------------------------------------------------------
# sort files from INBOX to REVIEW

if [[ -d "$DIR_SRC" ]] ; then
	cd $( realpath "$DIR_SRC" )
	printToLog "Work directory (in-box): $DIR_SRC"
else
	die $ERR_DIR_NOT_FOUND "cd $DIR_SRC: No such file or directory."
fi

# --- move away unwanted files

printVerbose "Next step is to trash duplicates and move unwanted files."
(($DEBUG)) && pause - "Trash duplicates and move unwanted files"
photo_trash_duplicates .
photo_align_backup_file_names
photo_move . "$DIR_ERR" "$RGX_ERR"          "Find Error" || die $ERR_NOT_WRITEABLE "Solve above problems before trying again."
photo_move . "$DIR_ERR" "$RGX_BAD"          "Move Unwanted" # move unwanted files out of the way
photo_trash_duplicates "$DIR_ERR"


# --- heavy lifting START ---
#! ToDo: photo_sort() currently only works with '.' as INDIR
photo_sort . "$MOV_REV" "$RGX_MOV"          "Sort Movies"   # move and rename video clips amd movies
photo_sort . "$DIR_RAW" "$RGX_RAW|$RGX_ARC" "Sort RAW"      # move and rename RAW and archive files
photo_sort . "$DIR_EDT" "$RGX_EDT"          "Sort EDIT"     # move and rename edited files
photo_sort . "$DIR_REV" "$RGX_IMG"          "Sort Images"   # move and rename all remaining image files

# --- heavy lifting END ---

# per destination directory, check for duplicates
printVerbose "Next step is to remove duplicates from target directories."
(($DEBUG)) && pause - "Remove duplicates from target directories"

pushd "$DIR_RAW" >/dev/null
for d in $( ls -d [12]*/[12]* 2>/dev/null ) ; do
	[ -d "$d" ] || break
	photo_trash_duplicates "${DIR_ORG%/}/$d" "${DIR_RAW%/}/$d"
done

pushd "$DIR_REV" >/dev/null
for d in $( ls -d [12]*/[12]* 2>/dev/null ) ; do
	[ -d "$d" ] || break
	photo_trash_duplicates "${DIR_PIC%/}/$d" "${DIR_REV%/}/$d"
done

popd >/dev/null
popd >/dev/null


printInfo "Done - remaining files in $DIR_SRC"
find $( realpath "$DIR_SRC" ) -type f ! -name .DS_Store

# @Todo: in stage 2 use DIR_ORG instead of DIR_RAW 
# @Todo: in stage 2 use DIR_PIC instead of DIR_REV

#!## DEVELOP - CONTINUE HERE ####
exit                         ####
#!## DEVELOP - CONTINUE HERE ####



# --- stage 1 only -------------------------------------------------------------

	printInfo "searching for pictures which are actually also originals ..."

	# I. Find original raw files and copy to RAW/yyyy/yyyy-mm-dd/yyyymmdd-hhmmss[_ff].ext
	printInfo "... find original raw files and copy to RAW"
	(($DEBUG)) && pause

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
	(($DEBUG)) && pause

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
	(($DEBUG)) && pause

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
	(($DEBUG)) && pause

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
