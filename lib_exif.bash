#
# -*- mode: bash; tab-width: 4 -*-
#
# NAME
#   lib_exif.bash - Library of exiftool functions
#
# SYNOPSIS
#   source lib_exif.bash
#
# DESCRIPTION
#	This library defines following bash functions:
#
# FILES
#	All functions depend on the exiftool
#	(http://www.sno.phy.queensu.ca/~phil/exiftool/)
#
# AUTHOR
#	@author     Andreas Tusche    <antu-photo@andreas-tusche.de>
#	@copyright  (c) 2021-2021, Andreas Tusche <www.andreas-tusche.de>
#	@package    antu-photo
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# when       who  what
# ---------- ---- --------------------------------------------------------------
# 2021-01-10 AnTu created

DEBUG=${DEBUG-''}						# 0: do not 1: do print debug messages
                                        # 2: bash verbose, 3: bash xtrace
										# 9: bash noexec

#(( ${photo_lib_loaded:-0} )) && return 0 # load me only once
((DEBUG)) && echo -n "[ . $BASH_SOURCE "

################################################################################
# config for this library
################################################################################

exif_DEVELOP=1                         # special settings for while developing
exif_MY_VERSION='$Revision: 0.0 $'     # version of this library



#===============================================================================
# NAME
#	exif_find_images_and_sidecars - find files which meet a condition
# 
# SYNOPSIS
#	exif_find_images_and_sidecars REGEXP CONDITIONS
#
# DESCRIPTION
#	Search images which meet the given conditions and store their names in the
#	file args_IMG.tmp, one line per image file name. Sidecarfiles with the same 
#	file base name are stored in  args_CAR.tmp.
# 
# OPTIONS
#	REGEXP      Regular Expressions for finding images
#	CONDITIONS  ExifTool condtions for images
#
# GLOBALS
#	INDIR    Directory
#	RGX_CAR  Regular Expressions for finding sidecar files
#	
# FILES
#	args_CAR.tmp  ExifTool arguments to copy tags from image to SideCar, e.g.
#		-tagsfromfile
#		./image_one.jpg
#		-srcfile
#		./image_one.jpg.dop
#		./image_one.jpg.dop
#		-execute
#
#	args_IMG.tmp  ExifTool arguments with image file names
#
# EXAMPLE
#	exif_find_images_and_sidecars '*' \
#		-if '$SequenceNumber' \
#		-if '$SequenceNumber ne "Single"' \
#		-if '$SequenceNumber ne 0'
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.210123===

function exif_find_images_and_sidecars() { # REGEXP CONDITIONS
	printDebug "${FUNCNAME}( $@ )"
	local _RX="$1"; shift
	local b e f

	if [[ "$_RX" == "" || "$_RX" == "*" ]]; then 
		unset _RX
	else 
		_RX="-ext ${_RX//|/ -ext }"
	fi

	rm args_CAR.tmp args_IMG.tmp 2>/dev/null
	exiftool \
		${_RX:- -ext '*' --ext DS_Store --ext localized} -i SYMLINKS \
		"$@" \
		-m -p '$directory/$filename' -q \
		"${INDIR}" |\
		grep -v "failed condition" |\
		while read b; do
			echo "$b" >>args_IMG.tmp
			for e in ${RGX_CAR//|/ }; do
				if [ -e "$b.$e" ] ; then
					f="$b.$e"
					echo -e "-tagsfromfile\n$b\n-srcfile\n$f\n$f\n-execute" >>args_CAR.tmp
				elif [ -e "${b%.*}.$e" ] ; then
					f="${b%.*}.$e"
					echo -e "-tagsfromfile\n$b\n-srcfile\n$f\n$f\n-execute" >>args_CAR.tmp
				fi
			done
		done

	if [[ $DEBUG > 1 ]]; then
		printDebug "args_IMG.tmp Images:"
		cat args_IMG.tmp 	
		printDebug "args_CAR.tmp SideCars:"
		cat args_CAR.tmp 	
	fi

	return
}



#===============================================================================
# NAME
#	exif_move_images_and_sidecars - rename sidecars and images
# 
# SYNOPSIS
#   exif_move_images_and_sidecars OUTDIR RULES_FOR_SIDECARS
#
# DESCRIPTION
#	Search images which meet the given conditions and store their names in the
#	file args_IMG.tmp, one line per image file name. Sidecarfiles with the same 
#	file base name are stored in  args_CAR.tmp.
# 
# OPTIONS
#	OUTDIR  destination directory, subdirectories will be created underneath
#		Use "--" if no move or copy of file is necessary
#
#	RULES_FOR_SIDECARS  Rules for setting tags on SideCar and Images files.
#		A trailing ".%e" will be removed to create rules for images.
#		ToDo: this is quite unhandy, make it more generic
#
# GLOBALS
#	DEBUG
#	DIR_CAR
#	LOGFILE
#
# FILES
#	args_CAR.tmp  ExifTool arguments to copy tags from image to SideCar, e.g.
#		-tagsfromfile
#		./image_one.jpg
#		-srcfile
#		./image_one.jpg.dop
#		./image_one.jpg.dop
#		-execute
#
#	args_IMG.tmp  ExifTool arguments with image file names
#
# EXAMPLE
#	exif_move_images_and_sidecars "~/Pictures/review/" \
#		'-FileName<${CreateDate}%+2c.${FileTypeExtension}.%e'
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.210131===

function exif_move_images_and_sidecars() { # OUTDIR RULES_FOR_SIDECARS
	printDebug "${FUNCNAME}( $@ )" 

	local _c _i _OUTDIR

	if [[ "$1" == "--" ]] ; then
		_c=
		_i=
	else
		_OUTDIR="$( realpath "$1" )"
		_c="${DIR_CAR%/}/%Y/%Y-%m-%d/%Y%m%d-%H%M%S"
		_i="${_OUTDIR%/}/%Y/%Y-%m-%d/%Y%m%d-%H%M%S"
	fi
	shift

#	printVerbose "Sidecars"
	[ -f args_CAR.tmp ] && exiftool \
		-@ args_CAR.tmp -common_args -m -r -progress: -q -q ${DEBUG:+"-v"} ${_c:+"-d" "$_c"} "$@" | tee -a "$LOGFILE"

#	printVerbose "Images"
	[ -f args_IMG.tmp ] && exiftool \
		-@ args_IMG.tmp -m -r -progress: -q -q ${DEBUG:+"-v"} ${_i:+"-d" "$_i"} "${@%%.%e}" | tee -a "$LOGFILE"

	return
}



#===============================================================================
# NAME
#	exif_sort_images_and_sidecars_time_frame - recursivly rename and sort image and side-car files
# 
# SYNOPSIS
#   exif_sort_images_and_sidecars_time_frame [OPTIONS] [INDIR [OUTDIR]]
#
# DESCRIPTION
#   This moves files from INDIR   or present directory and subfolders
#                      to OUTDIR  or ~/Pictures/sorted/YYYY/YYYY-MM-DD/
#
#	Images and RAW images are renamed to YYYYMMDD-hhmmss_ff.xxx, based on
#	their CreateDate and Frame Number. Frame Numbers usually only exist where an
#	analouge series of photos was digitalised. If two pictures still end up in
#	the same file-name, it will then be suffixed with a an incremental number:
#	YYYYMMDD-hhmmss_ff_n.xxx .
#
#	Sidecar files are renamed accordingly.
#
#	It's good practice to have checked for duplicates in the INDIR and OUTDIR
#	before invoking this function.
#
# OPTIONS
#	-n, --test  Dry-run testing of the file renaming feature, no files are moved
#	INDIR       defaults to the present working directory
#	OUTDIR      defaults to ~/Pictures/sorted/
#
# GLOBALS
#	DIR_PIC
#	GNU_mv
#	RGX_CAR
#	LOGFILE
#	TAG_DAT
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#===========================================================V.190825-V.210131===

function exif_sort_images_and_sidecars_time_frame() { # [-n|--test] INDIR OUTDIR
	printDebug "${FUNCNAME}( $@ )"
	local _d_option _FileName _rule _rule_ext _tag

	_FileName="-FileName"               # option to ExifTool -Filename or -TestName
	if [[ "$1" == "-n" || "$1" == "--test" ]]; then
		_FileName="-TestName"
		printWarning "Dry-run testing of the ExifTool file renaming feature."
		shift
	fi

	# ToDo: check what happens, if INDIR is not current dir '.' 
	INDIR="$(  realpath "${1:-$(pwd)}" )"                   # find files here
	OUTDIR="$( realpath "${2:-${DIR_PIC}}" )"               # put files in subdirectories
	_d_option="-d ${OUTDIR%/}/%Y/%Y-%m-%d/%Y%m%d-%H%M%S"    # subdirectories to OUTDIR
	_rule_ext='%+2c.${FileTypeExtension}.%e'                # rule for conflict counter, file extension + .%e for Sidecars


	# ToDo: This takes too long. First find files with SequenceNumber, then check for time-stamps
	printInfo "... sorting by time and sequence number (if any)" #--------------
	for _tag in $TAG_DAT; do
		printVerbose "    $_tag"
		exif_find_images_and_sidecars '*'\
			-if '$SequenceNumber' -if '$SequenceNumber ne "Single"' -if '$SequenceNumber ne 0'\
			-if2 '($'$_tag' && $'$_tag' ne "0000:00:00 00:00:00")'
		exif_move_images_and_sidecars "${OUTDIR%/}"\
			${_FileName}'<${'$_tag'}_${SequenceNumber;s/\b(\d)\b/0$1/g}'$_rule_ext
	done

	# ToDo: This takes too long. First find files with FrameNumber, then check for time-stamps
	printInfo "... sorting by time and frame (if any)" #------------------------
	for _tag in $TAG_DAT; do
		printVerbose "    $_tag"
		exif_find_images_and_sidecars '*'\
			-if '$FrameNumber'\
			-if2 '($'$_tag' && $'$_tag' ne "0000:00:00 00:00:00")'
		exif_move_images_and_sidecars "${OUTDIR%/}"\
			${_FileName}'<${'$_tag'}_${FrameNumber;s/\b(\d)\b/0$1/g}'$_rule_ext
	done

	printInfo "... sorting by time stamps" #------------------------------------
	for _tag in $TAG_DAT; do
		printVerbose "    $_tag"
		exif_find_images_and_sidecars '*'\
			-if2 '($'$_tag' && $'$_tag' ne "0000:00:00 00:00:00")'
		exif_move_images_and_sidecars "${OUTDIR%/}"\
			${_FileName}'<${'$_tag'}'$_rule_ext
	done

	printInfo "... sorting by date in file name " #-----------------------------
	exif_find_images_and_sidecars '*'\
		-if '($filename =~ /'"$RGX_DAT"'/) || ($filename =~ /'"$RGX_DTL"'/)'
	exif_move_images_and_sidecars "--"\
	    '-FileModifyDate<$Filename'
	exif_move_images_and_sidecars "${OUTDIR%/}"\
		-fast \
		${_FileName}'<${FileModifyDate}'$_rule_ext

	# printInfo "... sorting remaining by file times" #! do not do that
	# exif_find_images_and_sidecars '*'
	# exif_move_images_and_sidecars "${OUTDIR%/}"\
	# 	-fast \
	# 	${_FileName}'<${FileModifyDate}%+2c.${FileTypeExtension}.%e'

	# move remaining files (without useful time-stamp) to ERROR
	"$GNU_mv" --backup=numbered -f ${DEBUG:+"-v"} "${DIR_TMP%/}"/* "${DIR_ERR%/}"/ 2>/dev/null

	return
}

# ToDo: Streamline above exiftools calls in following function
#
# function exif_sort_images_time_frame_STREAMLINE_TEST() { # [-n|--test] INDIR OUTDIR
# 	printDebug "${FUNCNAME}( $@ )"
#
# 	local _FileName="-FileName"         # option to ExifTool -Filename or -TestName
# 	if [[ "$1" == "-n" || "$1" == "--test" ]]; then
# 		_FileName="-TestName"
# 		printWarning "Dry-run testing of the ExifTool file renaming feature."
# 		shift
# 	fi
#
# 	INDIR="$(  realpath "${1:-$(pwd)}" )"
# 	OUTDIR="$( realpath "${2:-${DIR_PIC}}" )"
#
# 	exiftool \
# 		-echo "INFO:  ... sorting by time and sequence number (if any)" \
# 		-ext "*" --ext DS_Store --ext localized -i SYMLINKS \
# 		-if '$SequenceNumber' -if '$SequenceNumber ne "Single"' -if '$SequenceNumber ne 0' \
# 		-m -r -progress: -q ${DEBUG:+"-v"} \
# 		-d "${OUTDIR%/}/%Y/%Y-%m-%d/%Y%m%d-%H%M%S"\
# 		${_FileName}'<${FileModifyDate}_${SequenceNumber;s/\b(\d)\b/0$1/g}%+2c.${FileTypeExtension}'\
# 		${_FileName}'<${ModifyDate}_${SequenceNumber;s/\b(\d)\b/0$1/g}%+2c.${FileTypeExtension}'\
# 		${_FileName}'<${DateTimeOriginal}_${SequenceNumber;s/\b(\d)\b/0$1/g}%+2c.${FileTypeExtension}'\
# 		${_FileName}'<${CreateDate}_${SequenceNumber;s/\b(\d)\b/0$1/g}%+2c.${FileTypeExtension}'\
# 		"${INDIR}" \
# 		-execute \
# 		-echo "INFO:  ... sorting by time and frame (if any)" \
# 		-ext "*" --ext DS_Store --ext localized -i SYMLINKS \
# 		-if '$FrameNumber' -m -r -progress: -q ${DEBUG:+"-v"} \
# 		-d "${OUTDIR%/}/%Y/%Y-%m-%d/%Y%m%d-%H%M%S"\
# 		${_FileName}'<${FileModifyDate}_${FrameNumber;s/\b(\d)\b/0$1/g}%+2c.${FileTypeExtension}'\
# 		${_FileName}'<${ModifyDate}_${FrameNumber;s/\b(\d)\b/0$1/g}%+2c.${FileTypeExtension}'\
# 		${_FileName}'<${DateTimeOriginal}_${FrameNumber;s/\b(\d)\b/0$1/g}%+2c.${FileTypeExtension}'\
# 		${_FileName}'<${CreateDate}_${FrameNumber;s/\b(\d)\b/0$1/g}%+2c.${FileTypeExtension}'\
# 		"${INDIR}" \
# 		-execute \
# 		-echo "INFO:  ... sorting by time stamps" \
# 		-ext "*" --ext DS_Store --ext localized -i SYMLINKS \
# 		-if2 '$CreateDate || $DateTimeOriginal || $ModifyDate' -m -r -progress: -q  ${DEBUG:+"-v"} \
# 		-d "${OUTDIR%/}/%Y/%Y-%m-%d/%Y%m%d-%H%M%S"\
# 		${_FileName}'<${MediaModifyDate}%+2c.${FileTypeExtension}'\
# 		${_FileName}'<${TrackModifyDate}%+2c.${FileTypeExtension}'\
# 		${_FileName}'<${ModifyDate}%+2c.${FileTypeExtension}'\
# 		${_FileName}'<${DateTimeOriginal}%+2c.${FileTypeExtension}'\
# 		${_FileName}'<${ContentCreateDate}%+2c.${FileTypeExtension}'\
# 		${_FileName}'<${MediaCreateDate}%+2c.${FileTypeExtension}'\
# 		${_FileName}'<${TrackCreateDate}%+2c.${FileTypeExtension}'\
# 		${_FileName}'<${CreateDate}%+2c.${FileTypeExtension}'\
# 		"${INDIR}" \
# 		-execute \
# 		-echo "INFO:  ... sorting remaining by file times" \
# 		-ext "*" --ext DS_Store --ext localized -i SYMLINKS \
# 		-fast -m -r -progress: -q ${DEBUG:+"-v"} \
# 		-d "${OUTDIR%/}/%Y/%Y-%m-%d/%Y%m%d-%H%M%S"\
# 		${_FileName}'<${FileModifyDate}%+2c.${FileTypeExtension}'\
# 		"${INDIR}" \
# 		-execute | tee -a ${LOGFILE} | grep -v "(failed condition)"
#
# 	return
# }



################################################################################
# make functions globally available
# TODO

if [[ "${exif_DEVELOP:-0}" == "0" ]]; then
	:
fi

# ! Do not remove or alter these last lines:
exif_lib_loaded=1; ((DEBUG)) && echo "]"
((exif_DEVELOP)) || readonly exif_lib_loaded
return 0

################################################################################
# END
################################################################################