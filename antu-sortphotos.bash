#!/bin/bash
#
# NAME
#	antu-sortphotos.bash - move photos and videos to daily folders
#
# SYNOPSIS
#	antu-sortphotos.bash
#
# DESCRIPTION
# 	A quick wrapper around the 'exiftool' tool for my preferred directory
#	strucure. it moves
#		* movies        from     ~/Pictures/INBOX/ and subfolders
#		                to       ~/Movies/YYYY/YYYY-MM-DD/
#		* movies        from     ~/Movies/
#		                to       ~/Movies/YYYY/YYYY-MM-DD/
#		* raw images    from     ~/Pictures/INBOX/ and subfolders
#		                to       ~/Pictures/RAW/YYYY/YYYY-MM-DD/
#		* edited images from     ~/Pictures/INBOX/ and subfolders to
#		                to       ~/Pictures/edit/YYYY/YYYY-MM-DD/
#		* photos        from     ~/Pictures/INBOX/ and subfolders
#		                to       ~/Pictures/sorted/YYYY/YYYY-MM-DD/
#
#	The default direcories can be overwritten by the antu-photo.cfg file.
#
#	Before actually working on those files, unwanted files - those which are
#	actually directries on Mac OS X - are move in a separate folder. They are
#	recognised by their file extension:
# 		.app .dmg .icbu .imovielibrary .keynote .oo3 .mpkg .numbers .pages
#		.photoslibrary .pkg .theater .webarchive
#
# 	Movies are sorted first. They are recognised by their file extension:
#		.3g2 .3gp .asf .avi .drc .flv .f4v .f4p .f4a .f4b .lrv .m4v .mkv .mov
#		.qt .mp4 .m4p .moi .mod .mpg, .mp2 .mpeg .mpe .mpv .mpg .mpeg, .m2v .ogv
#		.ogg .pgi .rm .rmvb .roq .svi .vob .webm .wmv .yuv
#
#	Raw images are recognised by their file extension:
#		.3fr .3pr .ari .arw .bay .cap .ce1 .ce2 .cib .cmt .cr2 .craw .crw .dc2
#		.dcr .dcs .dng .eip .erf .exf .fff .fpx .gray .grey .gry .iiq .kc2 .kdc
#		.kqp .lfr .mdc .mef .mfw .mos .mrw .ndd .nef .nop .nrw .nwb .olr .orf
#		.pcd .pef .ptx .r3d .ra2 .raf .raw .rw2 .rwl .rwz .sd[01] .sr2 .srf .srw
#		.st[45678] .stx .x3f .ycbcra
#
#	Edited images are recognised by their file extension:
#		.afphoto .bmp .eps .pdf .psd .tif .tiff
#
#	All files are checked, if their EXIF timestamps had been corrupted, and are
#	fixed, if necessary. It is expected that they are identical or increasing in
#	this order:
#		CreateDate ≤ DateTimeOriginal ≤ ModifyDate ≤ FileModifyDate
#		           ≤ FileInodeChangeDate ≤ FileAccessDate
#
#	Images and RAW images are renamed to YYYYMMDD-hhmmss.xxx, based on their
#	CreateDate. If two pictures were taken at the same second, the filename will
#	be suffixed with a an incremental number: YYYYMMDD-hhmmss_n.xxx .
#
#	In a second invocation, with option '--stage2', pictures will be resorted
#		* photos        from     ~/Pictures/sorted/ and subfolders
#		                to       ~/Pictures/YYYY/YYYY-MM-DD/
#
# FILES
#	Uses exiftool (http://www.sno.phy.queensu.ca/~phil/exiftool/)
#
# BUGS
#	The exiftool may bail out on non-ascii characters in the original filename.
#
# AUTHOR
#	@author     Andreas Tusche
#	@copyright  (c) 2017, Andreas Tusche 
#	@package    antu-photo
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# 2015-11-05 AnTu initial version using sortphoto python script
# 2015-12-05 AnTu added --stage2 option
# 2017-04-09 AnTu got rid of python script, now using exiftool directly

# config
CMD_checktimes=~/Develop/antu-photo/photo-check-times.bash
CMD_correcttim=~/Develop/antu-photo/photo-correct-times.bash
CMD_sortphotos=~/Develop/antu-photo/photo-sort-time.bash

DIR_EDT=~/Pictures/edit/
DIR_SRC=~/Pictures/INBOX/
DIR_PIC=~/Pictures/sorted/
DIR_RAW=~/Pictures/RAW/
DIR_MOV=~/Movies/
DIR_ERR=~/Pictures/ERROR/

DIR_SRC_2=~/Pictures/sorted/
DIR_PIC_2=~/Pictures/

# --- nothing beyond this line needs configuration -----------------------------

if [ -e "${0%/*}/antu-photo.cfg" ]; then . "${0%/*}/antu-photo.cfg"; fi
if [ -e ./antu-photo.cfg ]; then . ./antu-photo.cfg; fi

if [ "$1" == "--stage2" ] ; then
	DIR_SRC=$DIR_SRC_2
	DIR_PIC=$DIR_PIC_2
fi

# MAIN

cd "${DIR_SRC%/}"

if [ "$1" != "--stage2" ] ; then

	DIR_TMP="${DIR_PIC%/}/tmp_sortphotos/"
	mkdir -p "$DIR_TMP"
	mkdir -p "$DIR_ERR"


	# move errornous files out of the way
	echo -e "\nCheck File Types ...\n--------------------"
	find . -regextype posix-egrep -iregex ".*\.(app|dmg|icbu|imovielibrary|keynote|oo3|mpkg|numbers|pages|photoslibrary|pkg|theater|webarchive)" -exec mv -v --backup=t "{}" "${DIR_ERR%/}"/ \;

	for f in "${DIR_ERR%/}"/*.~*; do
		if [[ ! -e $f ]]; then break; fi
		n=${f%~*}
		e=${f#*.}
		mv -n -v "${f}" "${f%%.*}_${n#*~}.${e%.*}"
	done	


	# first move and rename Videos
	echo -e "\nMovies ...\n--------------------"
	find . -regextype posix-egrep -iregex ".*\.(3g2|3gp|asf|avi|drc|flv|f4v|f4p|f4a|f4b|lrv|m4v|mkv|mod|moi|mov|qt|mp4|m4p|mpg|mp2|mpeg|mpe|mpv|mpg|mpeg|m2v|ogv|ogg|pgi|rm|rmvb|roq|svi|vob|webm|wmv|yuv)" -exec mv -v --backup=t "{}" "${DIR_TMP%/}"/ \;

	for f in "${DIR_TMP%/}"/*.~*; do
		if [[ ! -e $f ]]; then break; fi
		n=${f%~*}
		e=${f#*.}
		mv -n -v "${f}" "${f%%.*}_${n#*~}.${e%.*}"
	done	

	$CMD_checktimes "$DIR_TMP" | $CMD_correcttim | bash
	$CMD_sortphotos "$DIR_TMP" "$DIR_MOV"

	# then move and rename RAW files
	echo -e "\nRAW ...\n--------------------"
	find . -regextype posix-egrep -iregex ".*\.(3fr|3pr|ari|arw|bay|cap|ce1|ce2|cib|cmt|cr2|craw|crw|dc2|dcr|dcs|dng|eip|erf|exf|fff|fpx|gray|grey|gry|iiq|kc2|kdc|kqp|lfr|mdc|mef|mfw|mos|mrw|ndd|nef|nop|nrw|nwb|olr|orf|pcd|pef|ptx|r3d|ra2|raf|raw|rw2|rwl|rwz|sd[01]|sr2|srf|srw|st[45678]|stx|x3f|ycbcra)" -exec mv -v --backup=t "{}" "${DIR_TMP%/}"/ \;

	for f in "${DIR_TMP%/}"/*.~*; do
		if [[ ! -e $f ]]; then break; fi
		n=${f%~*}
		e=${f#*.}
		mv -n -v "${f}" "${f%%.*}_${n#*~}.${e%.*}"
	done

	$CMD_checktimes "$DIR_TMP" | $CMD_correcttim | bash
	$CMD_sortphotos "$DIR_TMP" "$DIR_RAW"


	# then move and rename edited files
	echo -e "\nEDIT ...\n--------------------"
	find . -regextype posix-egrep -iregex ".*\.(afphoto|bmp|eps|pdf|psd|tif|tiff)" -exec mv -v --backup=t "{}" "${DIR_TMP%/}"/ \;

	for f in "${DIR_TMP%/}"/*.~*; do
		if [[ ! -e $f ]]; then break; fi
		n=${f%~*}
		e=${f#*.}
		mv -n -v "${f}" "${f%%.*}_${n#*~}.${e%.*}"
	done

	$CMD_checktimes "$DIR_TMP" | $CMD_correcttim | bash
	$CMD_sortphotos "$DIR_TMP" "$DIR_EDT"

fi

# move and rename all picture files 
echo -e "\nPictures ...\n--------------------"
$CMD_checktimes "$DIR_SRC" | $CMD_correcttim | bash
$CMD_sortphotos "$DIR_SRC" "$DIR_PIC"


# finally clean up
rm -d "$DIR_TMP"

