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
#	strucure. it moves
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
#	Before actually working on the photos, unwanted files - e.g. those which are
#	actually directries on Mac OS X - are moved to a separate folder. They are
#	recognised by their file extension:
#		.app .dmg .icbu .imovielibrary .keynote .oo3 .mpkg .numbers .pages
#		.photoslibrary .pkg .theater .webarchive
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
#	@author     Andreas Tusche
#	@copyright  (c) 2017-2018, Andreas Tusche
#	@package    antu-photo
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# 2015-11-05 AnTu initial version using sortphoto python script
# 2015-12-05 AnTu added --stage2 option
# 2017-04-09 AnTu got rid of python script, now using exiftool directly
# 2018-12-30 AnTu added call to trash-dupliactes

# default config

# --- nothing beyond this line needs configuration -----------------------------
for d in "${0%/*}" ~ . ; do source "$d/.antu-photo.cfg" 2>/dev/null || source "$d/antu-photo.cfg" 2>/dev/null; done

# The 2nd stage moves files to their final local destination
MYSTAGE=1
if [[ "$1" == "-2" || "$1" == "--stage2" ]] ; then
	MYSTAGE=2
	DIR_SRC=$DIR_SRC_2
	DIR_PIC=$DIR_PIC_2
fi

# === MAIN =====================================================================

cd "${DIR_SRC%/}"

mkdir -p "$DIR_TMP"
mkdir -p "$DIR_ERR"

if [ "$MYSTAGE" == "1" ] ; then
# --- stage 1 ------------------------------------------------------------------

# move errornous files out of the way
echo -e "\nCheck File Types ...\n--------------------"
find -E . -iregex ".*\.($RGX_ERR)" -exec mv --backup=numbered -f ${DEBUG:+"-v"} "{}" "${DIR_ERR%/}"/ \;

for f in "${DIR_ERR%/}"/*.~*; do
	if [[ ! -e $f ]]; then break; fi
	n=${f%~*}
	e=${f#*.}
	mv -n ${DEBUG:+"-v"} "${f}" "${f%%.*}_${n#*~}.${e%.*}"
done

# move and rename video clips amd movies
echo -e "\nMovies ...\n--------------------"
find -E . -iregex ".*\.($RGX_MOV)" -exec mv --backup=numbered -f ${DEBUG:+"-v"} "{}" "${DIR_TMP%/}"/ \;

for f in "${DIR_TMP%/}"/*.~*; do
	if [[ ! -e $f ]]; then break; fi
	n=${f%~*}
	e=${f#*.}
	mv -n ${DEBUG:+"-v"} "${f}" "${f%%.*}_${n#*~}.${e%.*}"
done

if [[ $CORRECTTIM == 1 ]] ; then $CMD_correcttim "${DIR_TMP%/}" ; fi
if [[ $TRASHDUPES == 1 ]] ; then $CMD_trashdupes "${DIR_TMP%/}" "$DIR_MOV%/}" ; fi
$CMD_sortphotos "$DIR_TMP" "$DIR_MOV"

# then move and rename RAW files
# @ToDo: Sidecar files .cos .dop .nks .pp3 .?s.spd .xmp
echo -e "\nRAW ...\n--------------------"
find -E . -iregex ".*\.($RGX_RAW)" -exec mv --backup=numbered -f ${DEBUG:+"-v"} "{}" "${DIR_TMP%/}"/ \;

for f in "${DIR_TMP%/}"/*.~*; do
	if [[ ! -e $f ]]; then break; fi
	n=${f%~*}
	e=${f#*.}
	mv -n ${DEBUG:+"-v"} "${f}" "${f%%.*}_${n#*~}.${e%.*}"
done

if [[ $CORRECTTIM == 1 ]] ; then $CMD_correcttim "${DIR_TMP%/}" ; fi
if [[ $TRASHDUPES == 1 ]] ; then $CMD_trashdupes "${DIR_TMP%/}" "${DIR_RAW%/}" ; fi
$CMD_sortphotos "$DIR_TMP" "$DIR_RAW"

# then move and rename edited files
# @ToDo: Sidecar files .cos .dop .nks .pp3 .?s.spd .xmp
echo -e "\nEDIT ...\n--------------------"
find -E . -iregex ".*\.($RGX_EDT)" -exec mv --backup=numbered -f ${DEBUG:+"-v"} "{}" "${DIR_TMP%/}"/ \;

for f in "${DIR_TMP%/}"/*.~*; do
	if [[ ! -e $f ]]; then break; fi
	n=${f%~*}
	e=${f#*.}
	mv -n ${DEBUG:+"-v"} "${f}" "${f%%.*}_${n#*~}.${e%.*}"
done

if [[ $CORRECTTIM == 1 ]] ; then $CMD_correcttim "${DIR_TMP%/}" ; fi
if [[ $TRASHDUPES == 1 ]] ; then $CMD_trashdupes "${DIR_TMP%/}" "${DIR_EDT%/}" ; fi
$CMD_sortphotos "$DIR_TMP" "$DIR_EDT"

fi
# --- stage 1 and 2 ------------------------------------------------------------

# move and rename all remaining picture files
echo -e "\nPictures ...\n--------------------"
find -E . -iregex ".*\.($RGX_IMG)" -not -path "${DIR_TMP%/}/*" -exec mv --backup=numbered -f ${DEBUG:+"-v"} "{}" "${DIR_TMP%/}"/ \;

for f in "${DIR_TMP%/}"/*.~*; do
	if [[ ! -e $f ]]; then break; fi
	n=${f%~*}
	e=${f#*.}
	mv -n ${DEBUG:+"-v"} "${f}" "${f%%.*}_${n#*~}.${e%.*}"
done

if [[ $CORRECTTIM == 1 ]] ; then $CMD_correcttim "${DIR_TMP%/}" ; fi
if [[ $TRASHDUPES == 1 ]] ; then $CMD_trashdupes "${DIR_TMP%/}" "${DIR_PIC%/}" ; fi
$CMD_sortphotos "$DIR_TMP" "$DIR_PIC"

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
