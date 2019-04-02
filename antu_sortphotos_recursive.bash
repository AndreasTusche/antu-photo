#!/bin/bash

# NAME
# antu_sortphotos_recursive.bash - move photos and videos to daily folders
#
# SYNOPSIS
# antu_sortphotos_recursive.bash
#
# DESCRIPTION
# A quick wrapper around the 'sortphotos' tool for my preferred directory
# strucure
#  * moves movies from     ~/Pictures/sort_me/ and subfolders to ~/Movies/yyyy/yyyy-mm-dd/
#  * moves movies from     ~/Movies/                          to ~/Movies/yyyy/yyyy-mm-dd/
#  * moves raw images from ~/Pictures/sort_me/ and subfolders to ~/Pictures/RAW/yyyy/yyyy-mm-dd/
#  * moves edited images f ~/Pictures/sort_me/ and subfolders to ~/Pictures/edit/yyyy/yyyy-mm-dd/
#  * moves photos from     ~/Pictures/sort_me/ and subfolders to ~/Pictures/sorted/yyyy/yyyy-mm-dd/
#
# Movies are sorted first. They are recognised by their file extension:
#	.3g2 .3gp .asf .avi .drc .flv .f4v .f4p .f4a .f4b .m4v .mkv .mov .qt .mp4
#	.m4p .mpg, .mp2 .mpeg .mpe .mpv .mpg .mpeg, .m2v .ogv .ogg .rm .rmvb .roq
#	.svi .vob .webm .wmv .yuv
#
# Raw images are recognised by their file extension:
#	.3fr .3pr .ari .arw .bay .cap .ce1 .ce2 .cib .cmt .cr2 .craw .crw .dc2 .dcr
#	.dcs .dng .eip .erf .exf .fff .fpx .gray .grey .gry .iiq .kc2 .kdc .kqp .lfr
#	.mdc .mef .mfw .mos .mrw .ndd .nef .nop .nrw .nwb .olr .orf .pcd .pef .ptx 
#	.r3d .ra2 .raf .raw .rw2 .rwl .rwz .sd[01] .sr2 .srf .srw .st[45678] .stx
#	.x3f .ycbcra
#
# Edited images are recognised by their file extension:
#	.bmp .eps .pdf .psd .tif .tiff
#
# Images and RAW images are renamed to YYYYMMDD-hhmmss.xxx, duplicates are not
# kept but if two files were taken at the same second, the filename will be
# suffixed with a an incremental number: YYYYMMDD-hhmmss_n.xxx .
#
# In a second invocation, with option '--stage2', they will be resorted
#  * moves movies from     ~/Pictures/sorted/ and subfolders to ~/Movies/yyyy/yyyy-mm-dd/
#  * moves movies from     ~/Movies/                         to ~/Movies/yyyy/yyyy-mm-dd/
#  * moves raw images from ~/Pictures/sorted/ and subfolders to ~/Pictures/RAW/yyyy/yyyy-mm-dd/
#  * moves photos from     ~/Pictures/sorted/ and subfolders to ~/Pictures/yyyy/yyyy-mm-dd/
#
# FILES
# Uses https://github.com/andrewning/sortphotos
#
# BUGS
# The sortphotos tool may bail out on non-ascii characters in the original filename.
#
# SEE ALSO
# antu_sortphotos.bash

# 2015-11-05 AnTu initial version
# 2015-12-05 AnTu added --stage2 option

# sortphoto.py command line arguments
# '-r', '--recursive' search src_dir recursively
# '-c', '--copy',     copy files instead of move
# '-s', '--silent'    don't display parsing details.
# '-t', '--test'      run a test.  files will not be moved/copied\ninstead you will just a list of would happen
# '--sort'            choose destination folder structure using datetime format
#                     https://docs.python.org/2/library/datetime.html#strftime-and-strptime-behavior.
#                     Use forward slashes / to indicate subdirectory(ies) (independent of your OS convention).
#                     The default is '%%Y/%%m-%%b', which separates by year then month
#                     with both the month number and name (e.g., 2012/02-Feb).
# '--rename'          rename file using format codes
#                     https://docs.python.org/2/library/datetime.html#strftime-and-strptime-behavior.
#                     default is None which just uses original filename.
# '--keep-duplicates' If file is a duplicate keep it anyway (after renaming).
# '--day-begins'      hour of day that new day begins (0-23)
#                     defaults to 0 which corresponds to midnight.  Useful for grouping pictures with previous day.
# '--ignore-groups'   a list of tag groups that will be ignored for date informations.
#                     list of groups and tags here: 
#                     by default the group \'File\' is ignored which contains file timestamp data
# '--ignore-tags'     a list of tags that will be ignored for date informations.
#                     list of groups and tags here: http://www.sno.phy.queensu.ca/~phil/exiftool/TagNames/
#                     the full tag name needs to be included (e.g., EXIF:CreateDate)')
# '--use-only-groups' specify a restricted set of groups to search for date information e.g., EXIF
# '--use-only-tags'   specify a restricted set of tags to search for date information e.g., EXIF:CreateDate
CMD_sortphotos=~/Develop/sortphotos/src/sortphotos.py

DIR_EDT=~/Pictures/edit/
DIR_SRC=~/Pictures/sort_me/
DIR_PIC=~/Pictures/sorted/
DIR_RAW=~/Pictures/RAW/
DIR_MOV=~/Movies/

if [ "$1" == "--stage2" ] ; then
	DIR_SRC=~/Pictures/sorted/
	DIR_PIC=~/Pictures/
fi

NAME="%Y%m%d-%H%M%S"
SORT="%Y/%Y-%m-%d/"


# -------------------------------------
# MAIN
# -------------------------------------
cd "${DIR_SRC%/}"
DIR_TMP="${DIR_PIC%/}/tmp_sortphotos/"
mkdir -p "$DIR_TMP"


if [ "$1" != "--stage2" ] ; then

	# first move Videos out of the way
	echo -e "\nMovies ...\n--------------------"
	find . -regextype posix-egrep -iregex ".*\.(3g2|3gp|asf|avi|drc|flv|f4v|f4p|f4a|f4b|m4v|mkv|mov|qt|mp4|m4p|mpg|mp2|mpeg|mpe|mpv|mpg|mpeg|m2v|ogv|ogg|rm|rmvb|roq|svi|vob|webm|wmv|yuv)" -exec mv -v --backup=t "{}" "${DIR_MOV%/}"/ \;

	for f in "${DIR_MOV%/}"/*.~*; do
		n=${f%~*}
		e=${f#*.}
		mv -n -v "${f}" "${f%%.*}_${n#*~}.${e%.*}"
	done	

	$CMD_sortphotos "$DIR_MOV" "$DIR_MOV" --sort ${SORT%/}/


	# then move RAW out of the way
	echo -e "\nRAW ...\n--------------------"
	find . -regextype posix-egrep -iregex ".*\.(3fr|3pr|ari|arw|bay|cap|ce1|ce2|cib|cmt|cr2|craw|crw|dc2|dcr|dcs|dng|eip|erf|exf|fff|fpx|gray|grey|gry|iiq|kc2|kdc|kqp|lfr|mdc|mef|mfw|mos|mrw|ndd|nef|nop|nrw|nwb|olr|orf|pcd|pef|ptx|r3d|ra2|raf|raw|rw2|rwl|rwz|sd[01]|sr2|srf|srw|st[45678]|stx|x3f|ycbcra)" -exec mv -v --backup=t "{}" "${DIR_TMP%/}"/ \;

	for f in "${DIR_TMP%/}"/*.~*; do
		n=${f%~*}
		e=${f#*.}
		mv -n -v "${f}" "${f%%.*}_${n#*~}.${e%.*}"
	done

	$CMD_sortphotos "$DIR_TMP" "$DIR_RAW" --rename $NAME --sort ${SORT%/}/


	# then move edited files out of the way
	echo -e "\nEDIT ...\n--------------------"
	find . -regextype posix-egrep -iregex ".*\.(bmp|eps|pdf|psd|tif|tiff)" -exec mv -v --backup=t "{}" "${DIR_TMP%/}"/ \;

	for f in "${DIR_TMP%/}"/*.~*; do
		n=${f%~*}
		e=${f#*.}
		mv -n -v "${f}" "${f%%.*}_${n#*~}.${e%.*}"
	done

	$CMD_sortphotos "$DIR_TMP" "$DIR_EDT" --rename $NAME --sort ${SORT%/}/

fi

# then do all the rest
echo -e "\nPictures ...\n--------------------"
$CMD_sortphotos "$DIR_SRC" "$DIR_PIC" --recursive --rename $NAME --sort ${SORT%/}/


# finally clean up
rm -d "$DIR_TMP"

