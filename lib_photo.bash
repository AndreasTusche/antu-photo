#
# -*- mode: bash; tab-width: 4 -*-
################################################################################
#
# NAME
#   lib_photo.bash - Library of common functions for bash scripts
#
# SYNOPSIS
#   source lib_photo.bash
#
# DESCRIPTION
#	This library defines following bash functions:
#	- photo_align_backup_file_names
#	- photo_check_bash
#	- photo_check_dependencies
#	- photo_check_directories
#	- photo_check_files
#	- photo_create_directories
#	- photo_NASisMounted
#	- photo_isLocalWRK
#	- photo_move
#	- photo_parse_date
#	- photo_parse_filename
#	- photo_sort
#	- photo_trash
#	- photo_trash_duplicate
#	- photo_trash_duplicates
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
# 2018-12-30 AnTu created
# 2019-08-02 AnTu export functions to call this file only once
# 2019-08-23 AnTu moved photo_align_backup_file_names here

DEBUG=${DEBUG-''}						# 0: do not 1: do print debug messages
                                        # 2: bash verbose, 3: bash xtrace
										# 9: bash noexec

#(( ${photo_lib_loaded:-0} )) && return 0 # load me only once
((DEBUG)) && echo -n "[ . $BASH_SOURCE "

################################################################################
# config for this library
################################################################################

photo_DEVELOP=1                        # special settings for while developing
photo_MY_VERSION='$Revision: 0.0 $'    # version of this library

# determine the operating system
MAC=0; if [[ "${OSTYPE:0:6}" == "darwin" ]]; then MAC=1; fi
LNX=0; if [[ "${OSTYPE:0:5}" == "linux"  ]]; then LNX=1; fi # (likely on NAS)
WIN=0; if [[ "${OSTYPE:0:6}" == "cygwin" ]]; then WIN=1; fi



#===============================================================================
# NAME
#	photo_align_backup_file_names
#
# SYNOPSIS
#	photo_align_backup_file_names [DIRECTORY]
#
# DESCRIPTION
#	Rename files from the backup-style (of the mv command) to a filename with
#	sequence number, e.g.
#		"filename.ext.~1~" to "filename_01.ext"
#
#	If a binary-identical file (without ~number~ or with the destination file
#	name) already exists, then the source file will be moved to the trash.
#	Else the number will be incremented until it doesn't clash with existing
#	file names.
#
#	Side-effect: File names with a one-digit sequence number will be normalised
#	to a two-digit sequence number.
#
# OPTIONS
#	DIRECTORY  The path to a directory, defaults to current directory.
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.210103===

function photo_align_backup_file_names() { # [DIRECTORY]
	printDebug "${FUNCNAME}( $@ )"
	local DIR file tr t1 ex e1 sq ba nn cnt 

	DIR=$( realpath "${1:-$(pwd)}")
	[ -d "$DIR" ] || die $ERR_DIR_NOT_FOUND "${FUNCNAME}(): 1st parameter must be a directory. $DIR is not a directory"

	for file in "${DIR%/}"/*_[0-9].* "${DIR%/}"/*.~*; do
	
		if [[ -e $file ]]; then
			printDebugVar file
			photo_parse_filename "$file"          # reults in REPLY array 
			#// ((DEBUG)) && set -x
			tr="${REPLY[TRUNK]}"
			t1="${REPLY[TRUNK1]}"
			ex="${REPLY[EXTENSION]}"
			e1="${REPLY[EXTENSION1]}"
			sq="${REPLY[SEQUENCE]}"
			ba="${REPLY[BACKUP]}"
			#// ((DEBUG)) && set +x
			#? photo_trash_duplicate "${DIR%/}/${tr}.${e1}" "$file" && continue 1
			#? photo_trash_duplicate "${DIR%/}/${t1}.${e1}" "$file" && continue 1
			
			# increment new sequence number until it doesn't clash with existing files
			printf -v nn "%02d" $(( 10#${ba:-$sq} % 100 ))            # two digit numbering, interpret 08 and 09 as decimal
			cnt=0
			while [ -e "${DIR%/}/${t1}_${nn}.${e1}" ]; do
				#? photo_trash_duplicate "${DIR%/}/${t1}_${nn}.${e1}" "$file" && continue 2
				printf -v nn "%02d" $(( ( 10#$nn + 1 ) % 100 ))       # two digit numbering
				(( ++cnt > 100 )) && die $ERR_WARN "There are already 100 versions of '${DIR%/}/${t1}_*.${e1}'."
			done

			#// mv -n ${DEBUG:+"-v"} "${file}" "${DIR%/}/${t1}_${nn}.${e1}"
			mv -n "${file}" "${DIR%/}/${t1}_${nn}.${e1}"
			printToLog "renamed ${file} -> ${DIR%/}/${t1}_${nn}.${e1}"
		fi
	done

	return 0
}



#===============================================================================
# NAME
#	photo_check_bash - check bash version is of given version or newer	
#
# SYNOPSIS
#	photo_check_bash VERSION	
#
# DESCRIPTION
#	Check bash version is of given version or newer, else print a warning.		
#
# OPTIONS
#	VERSION  minimum version needed, as "#.#", i.e. version.subversion	
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.201204===

# check for correct shell version
function photo_check_bash() { # [VERSION]
	printDebug "${FUNCNAME}( $@ )"
	local MIN_BASH_VERSION=5.0 # recommended bash version as #.#

	[[ ${1-} =~ [0-9]\.[0-9] ]] && MIN_BASH_VERSION=$1

	if [[ ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]} < $MIN_BASH_VERSION ]]; then
		printWarning  "The version ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]} of bash is old. Please upgrade to version $MIN_BASH_VERSION."
		printWarning2 "\033[3m    brew install bash"
		printWarning2 "More information at https://itnext.io/upgrading-bash-on-macos-7138bd1066ba"
	fi
}


#===============================================================================
# NAME
#	photo_check_dependencies - check if necessary tools are installed
#
# SYNOPSIS
#	photo_check_dependencies	
#
# DESCRIPTION
#	Check bash is of the right version, and that following tools are installed:
#	- GNU coreutils
#	- exiftool
#	This also sets GNU coreutils at first position in the PATH
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.210103===

function photo_check_dependencies() {
	printDebug "${FUNCNAME}( $@ )"
	photo_check_bash 3.2
	$( date     --version >/dev/null 2>&1 )       || die $ERR_FILE_NOT_FOUND "The 'date' command from the 'coreutils' is not in the PATH or not installed."
	$( mv       --version >/dev/null 2>&1 )       || die $ERR_FILE_NOT_FOUND "The 'mv' command from the 'coreutils' is not in the PATH or not installed."
	$( realpath --version >/dev/null 2>&1 )       || die $ERR_FILE_NOT_FOUND "The 'realpath' command from the 'coreutils' is not in the PATH or not installed."

	#which -s brew                                || die $ERR_FILE_NOT_FOUND "Homebrew is not installed. See https://brew.sh ."
	which -s exiftool                             || die $ERR_FILE_NOT_FOUND "The 'exiftool' is not installed. See https://brew.sh ."
	which -s fdupes                               || die $ERR_FILE_NOT_FOUND "The 'fdupes' tool is not installed. See https://brew.sh ."

	[ -d /usr/local/opt/coreutils ]               || die $ERR_FILE_NOT_FOUND "The 'coreutils' are not installed."
#	[[ $PATH == *"coreutils"* ]]                  || export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
}



#===============================================================================
# NAME
#	photo_check_directories
#
# SYNOPSIS
#	photo_check_directories	[VARIBALE_NAME_FOR_DIRECTORY ...]
#
# DESCRIPTION
#	Check if the given or all the needed default directories exist.
#	See also antu-photo.cfg
#
# OPTIONS
#	VARIBALE_NAME_FOR_DIRECTORY
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.201204===

function photo_check_directories() { # [VARIBALE_NAME_FOR_DIRECTORY ...]
	printDebug "${FUNCNAME}( $@ )"
	local d dd

	if [[ ${#@} -gt 0 ]]; then
		dd=( $@ )
	else

		for d in DIR_PIC NAS_MNT NAS_PIC LOC_MNT LOC_PIC; do
			if [[ "${!d}" == "" || "${!d}" == "/" ]] ; then
				die $ERR_ERROR "Path $d='${!d}' must not be empty or root."
			fi
		done

		# names of directory variables # ToDo: Move this in the config file
		photo_DIRS_WRK_LOC=(         DIR_PIC DIR_RCY DIR_CAR DIR_CAT DIR_DUP DIR_EDT DIR_ERR DIR_ORG DIR_RAW DIR_REV DIR_SRC DIR_TMP DIR_MOV MOV_REV )
		photo_DIRS_NAS_RMT=( NAS_MNT NAS_PIC NAS_RCY NAS_CAR NAS_CAT NAS_DUP NAS_EDT NAS_ERR NAS_ORG NAS_RAW NAS_REV NAS_SRC NAS_TMP                 )
		photo_DIRS_NAS_LOC=( LOC_MNT LOC_PIC LOC_RCY LOC_CAR LOC_CAT LOC_DUP LOC_EDT LOC_ERR LOC_ORG LOC_RAW LOC_REV LOC_SRC LOC_TMP                 )

		photo_isLocalWRK   && dd=(          ${photo_DIRS_WRK_LOC[@]} ) && printDebug "Running on work computer."
		photo_isLocalNAS   && dd=(          ${photo_DIRS_NAS_LOC[@]} ) && printDebug "Running on NAS." 
		photo_NASisMounted && dd=( ${dd[@]} ${photo_DIRS_NAS_RMT[@]} ) && printDebug "The NAS $NAS_MAC is mounted on $NAS_MNT." \
		                                                               || printDebug "The NAS is not mounted."
	fi

	for d in ${dd[@]}; do
		if [[ -d ${!d} ]] ; then
			printVerbose "Found   directory $d ${!d}"
		else
			printWarning "Missing directory $d ${!d}"
			photo_DIRS_MISSING=( ${photo_DIRS_MISSING[@]:-} $d )
		fi
	done
}

#===============================================================================
# NAME
#	photo_check_files	
#
# SYNOPSIS
#	photo_check_files VARIBALE_NAME_FOR_FILES 	
#
# DESCRIPTION
#	Check if needed files exist.
#
# OPTIONS
#	VARIBALE_NAME_FOR_FILES	
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.201204===

function photo_check_files() {  # [VARIBALE_NAME_FOR_FILES ...]
	printDebug "${FUNCNAME}( $@ )"
	local f ff

	if [[ ${#@} -gt 0 ]]; then
		ff=( $@ )
	else
# ToDo: Trying without the other scripts, use functions instead
#//		photo_COMMANDS=( CMD_correcttim CMD_extractgps CMD_intrpltgps CMD_sortphotos CMD_trashdupes CMD_wakeup_nas LIB_antu_photo )
		photo_COMMANDS=( "" )
		photo_FILESGPS=( GPS_FMT )
		photo_LOGFILES=( LOGFILE )
		ff=( ${photo_COMMANDS[@]} ${photo_FILESGPS[@]} ${photo_LOGFILES[@]} )
	fi

	for f in ${ff[@]}; do
		if [[ -f ${!f} ]] ; then
			printVerbose "Found   file $f ${!f}"
		else
			printWarning "Missing file $f ${!f}"
		fi
	done
}



#===============================================================================
# NAME
#	photo_create_directories
#
# SYNOPSIS
#	photo_create_directories [VARIBALE_NAME_FOR_DIRECTORY ...]
#
# DESCRIPTION
#	This will create some or all missing directories defined in the antu-photo
#	configuration file.
#   A script to undo the creation of the directories will be written to 
#	undo_photo_create_directories_yymmdd_hhmmss.bash
#
# OPTIONS
#	VARIBALE_NAME_FOR_DIRECTORY  as defined in the antu-photo configuration file
#                                defaults to photo_DIRS_MISSING array, if set.
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.201213===
# ToDo: add sym link from REVIEW to MOVIE/REVIEW

function photo_create_directories() { # [VARIBALE_NAME_FOR_DIRECTORY ...]
	printDebug "${FUNCNAME}( $@ )"
	local _d d dd undo

	if [[ ${#@} -gt 0 ]]; then
		dd=( $@ )
	else
		dd=( ${photo_DIRS_MISSING[@]:-} )
	fi

	[[ ${#dd[@]} == 0 ]] && return 0

	undo="undo_photo_create_directories_$(date +%y%m%d_%H%M%S).bash"
	echo "#!/bin/bash" >$undo

	for d in ${dd[@]}; do
		_d="${!d}"
		printWarning  "The $d directory will be created at '$_d'."
		printWarning2 "This change is permanent!"
		mkdir -p "$_d"
		echo "rmdir -p \"$_d\" 2>/dev/null" >>$undo
		printToLog "Created $d directory at '$_d'."
	done

	printVerbose "To undo the creation of the directories, use script $undo."
	return 0
}



#===============================================================================
# NAME
#	photo_NASisMounted	
#
# SYNOPSIS
#	if $( photo_NASisMounted ); then ...
#
# DESCRIPTION
#	
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.201204===

function photo_NASisMounted() {
	[[ $MAC == 1 && -d "$NAS_MNT" ]]
}

#===============================================================================
# NAME
#	photo_isLocalWRK	
#
# SYNOPSIS
#	if $( photo_isLocalWRK ) ; then ...
#
# DESCRIPTION
#	Check if script runs on work computer
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.201204===

function photo_isLocalWRK() {
	[[ $MAC == 1 && -d "$DIR_PIC" ]]
}

function photo_isDate() {
	[[ "$1" =~ ^[0-9]{8}.[0-9]{6} ]]
}

#===============================================================================
# NAME
#	photo_isLocalNAS	
#
# SYNOPSIS
#	if $( photo_isLocalNAS ) ; then ...	
#
# DESCRIPTION
#	
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.201204===

function photo_isLocalNAS() {
	[[ $LNX == 1 && -d "$LOC_PIC" ]]
}



#===============================================================================
# NAME
#	photo_move
#
# SYNOPSIS
#	photo_move SOURCE_DIR DESTINATION_DIR REGULAR_EXPRESSION [MESSAGE]
#
# DESCRIPTION
#	Recursively find files that match the REGULAR_EXPRESSION in the SOURCE_DIR
#	and its sub-directories and move them all to the DESTINATION_DIR. 
#
# OPTIONS
#	SOURCE_DIR          source directory of images and side-cars
#	DESTINATION_DIR     destination directory, subdirectories will be created
#	REGULAR_EXPRESSION  file name extensions, as RegExp suitable for `find`
#	MESSAGE             optional message, displayed in verbose or debug mode
#
# ENVIRONMENT
#	DEBUG    0: no 1: debug putput
#	GNU_mv   path to the GNU version of the `mv`command
#	LOGFILE  path to the log file
#	MAC      0: if not running on Mac, 1: if running on Mac
#	RGX_CAR  Regular expression for side-car file name extensions
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.210111===
# @ToDo: find a better way to use the GNU mv command

function photo_move() { # SOURCE_DIR DESTINATION_DIR REGULAR_EXPRESSION [MESSAGE]
	printDebug "${FUNCNAME}( $@ )"
	local _from="$1" _to="$2" _regex="$3" _info="${4-}"
	local _f _retval

	pushd "$_from" >/dev/null

	_retval=$(
		find ${MAC:+-E} . -iregex ".*\.($_regex)" -print0 2>/dev/null | while IFS= read -r -d $'\0' _f; do 

			# move the image
			"$GNU_mv" --backup=numbered -f ${DEBUG:+"-v"} "${_f}" "${_to%/}"/ 2>/dev/null | tee -a "$LOGFILE" >&2

			if [[ $? != 0  ]] ; then
				_retval=1
				echo -e "$(date +'%F %T') \033[1;91mERROR  :\033[0;91m Failed moving $( realpath "$_f" ) \033[0m " >&2
			fi

			# move the sidecar file (RGX_CAR="cos|dop|gpx|nks|pp3|.?s.spd")
			"$GNU_mv" --backup=numbered -f ${DEBUG:+"-v"} -t "${_to%/}"/ \
				$( compgen -f "${_f}."    | grep -E "$RGX_CAR" ) \
				$( compgen -f "${_f%.*}." | grep -E "$RGX_CAR" ) \
				2>/dev/null \
				| tee -a "$LOGFILE" >&2
			echo $_retval
		done
	)
	
	photo_align_backup_file_names "${_to%/}"
	popd >/dev/null
	return $_retval
}



#===============================================================================
# NAME
#	photo_parse_date
#
# SYNOPSIS
#	photo_parse_date [-f|-t|+FORMAT] FILENAME
#
# DESCRIPTION
#	Parsing the filename for date and time. It will be interpreted in the order
#	of "Y M D h m s"
#	This is very flexible about the actual format of input date/time values, and
#	will attempt to reformat any values into the standard format. Any separators
#	may be used (or in fact, none at all). The first 4 consecutive digits found
#	in the value are interpreted as the year, then next 2 digits are the month,
#	and so on. The year must be 4 digits but 2 digits are allowed if the
#	subsequent character is a non-digit, and other fields are expected to be 2
#	digits, but a single digit is allowed if the subsequent character is a
#	non-digit. If a field value exceeds the maximum allowed number, e.g. day 32
#	or hour 25, then the excess will just be added, e.g. "1999-02-29 00:64:00"
#	will be normalised to "1999-03-01 01:04:00"
#
# OPTIONS
#	-f	return a string for a new filename like YYYYMMDD-hhmmss (default)
#	-t	return a string like YYYY-MM-DDThh:mm:ss
#   +FORMAT 	date format (see strftime(3))
#	FILENAME	Input filename
#
# BUGS
#	Dates before 1900 are not supported. Two-digit years <71 will be interpreted
#	as years 2000 to 2070, and >70 as years 1970 to 1999 (limitations of `date`)
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.210103===

function photo_parse_date() { # [-f|-t] FILENAME
	printDebug "${FUNCNAME}( $@ )"
	local format="%Y %m %d %H %M %S" out str t Y M D h m s

	case ${1} in
		-f)   format="%Y%m%d-%H%M%S";     shift ;;
		-t)   format="%Y-%m-%dT%H:%M:%S"; shift ;;
		+*%*) format=${1:1};              shift ;;
	esac

	str=$(basename "$1")
	#                               |-YY-------------------|        |-MM-----|         |-DD-----|         |-hh-----|         |-mm-----|         |-ss-----|
	[[ "${str%.*}00000000000000" =~ ([1-9][0-9]{3}|[0-9]{2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2}).* ]]
	read t Y M D h m s <<< ${BASH_REMATCH[@]//[!0-9]/}
	printDebug "yyyy-mm-dd hh:mm:ss = '${Y-}-${M-}-${D-} ${h-}:${m-}:${s-}'"
	(( M = M < 1 ? 1 : M ))
	(( D = D < 1 ? 1 : D ))
	if $( date --version >/dev/null 2>&1 ) ; then # GNU 'date'
		date +"$format" -d "$Y-1-1 +$(( 10#$M-1 )) months +$(( 10#$D-1 )) days +$h hours +$m minutes +$s seconds"
	else # Mac OS 'date'
		date -j -v+$(( 10#$M-1 ))m -v+$(( 10#$D-1 ))d -v+${h}H -v+${m}M -v+${s}S "01010000${Y}.00" +"$format"
	fi
}



#===============================================================================
# NAME
#	photo_parse_filename
#
# SYNOPSIS
#	photo_parse_filename FILENAME
#
# DESCRIPTION
#   This will split a filename in its parts: DIRECTORY BASENAME TRUNK
#	TRUNK1 EXTENSION EXTENSION1 SEQUENCE BACKUP YEAR MONTH DAY HOUR MINUTE
#	SECOND CENTISECOND.
#
#	TRUNK      is the file base-name without extension.
#	TRUNK1     is the TRUNK without sequence number, if any
#	EXTENSION  contains all filename extensions without the first leading dot
#	EXTENSION1 is the EXTENSION without backup-number, if any
#	SEQUENCE   is a number after the last underscore in the TRUNK
#	BACKUP     is a number between two '~' (tilde) in the file name extension
#
#	The date and time are taken from the numeric characters of the filename in
#	the order of "Y M D h m s cs", where cs is the two-digit centi-second.
#	This is very flexible about the actual format of input date/time values, and
#	will attempt to reformat any values into the standard format. Any separators
#	may be used (or in fact, none at all). The first 4 consecutive digits found
#	in the value are interpreted as the year, then next 2 digits are the month,
#	and so on. The year must be 4 digits but 2 digits are allowed if the
#	subsequent character is a non-digit. Other fields are expected to be 2
#	digits, but a single digit is allowed if the subsequent character is a
#	non-digit. If a field value exceeds the maximum allowed number, e.g. day 32
#	or hour 25, then the excess will just be added, e.g. "1999-02-29 00:64:00"
#	will be normalised to "1999-03-01 01:04:00"
#
#	The resulting substrings will be returned in the REPLY array with indices as
#	in above order, e.g. DIRECTORY in REPLY[1], ..., CENTISECOND in REPLY[15].
#
# OPTIONS
#	FILENAME  Input filename. A file of that name does not need to exist.
#
# EXAMPLE
# 	To parse a file name and retrieve all elements in the calling script, the
#	'read' command can be used. This will only work, if the path and the file-
#	name do not contain any white space characters.
#		photo_parse_filename "Pictures/2019-01-21/20190121-081751_42.jpg.dop"
#		read dn bn tr t1 ex e1 sq bu yy mm dd hh mi ss cs <<< ${REPLY[*]}
#		echo $tr # prints "20190121-081751_42"
#
# 	To parse a file name and retrieve specific elements in the calling script,
#	the REPLY array can be used. This also works, if the path or the file-
#	name not contain some white space characters.
#		photo_parse_filename "Pictures/2019-01-21/20190121-081751_42.jpg.dop"
#		tr="${REPLY[TRUNK1]}"
#		echo $t1 # prints "20190121-081751"
#
# BUGS
#	Two-digit years <71 will be interpreted as years 2000 to 2070, and >70 as
#	years 1970 to 1999 (limitation of `date`).
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.210514===

function photo_parse_filename() { # FILENAME
	printDebug "${FUNCNAME}( $@ )"
    local fn dn bn tr t1 ex e1 sq bu yy mm dd hh mi ss cs x yoffset=0

    fn="$1"                             # file name with path                   /path1/path2/20170320-065042_01.jpg.dop.~3~
    dn="${fn%/*}"                       # directory name                        /path1/path2
    bn="${fn##*/}"                      # file base name                        20170320-065042_01.jpg.dop.~3~
    tr="${bn%%.*}"                      # trunk of base name                    20170320-065042_01
    ex="${bn#*.}"                       # extension(s)                          jpg.dop.~3~
    e1="${ex%%.~*}"                     # extension(s) w/o backup number        jpg.dop

    #// example for future use, if needed
	#//
	#// [[ "${tr}___" =~ ([^-_]*)[-_]([^-_]*)[-_]([^-_]*) ]]  
	#// p1="${BASH_REMATCH[1]}"             # 1st part delimited by "-" or "_"      20170320
	#// p2="${BASH_REMATCH[2]}"             # 2nd part delimited by "-" or "_"      065042
	#// p3="${BASH_REMATCH[3]}"             # 3rd part delimited by "-" or "_"      01
	#// 
    #// [[ "${ex}..." =~ ([^.]*)\.([^.]*)\.([^.]*) ]]  
    #// x1="${BASH_REMATCH[1]}"             # 1st extension                         jpg
    #// x2="${BASH_REMATCH[2]}"             # 2nd extension                         dop
    #// x3="${BASH_REMATCH[3]}"             # 3rd extension                         ~3~

    [[ "$bn" =~ .*_([0-9]*)\. ]]  
    sq="${BASH_REMATCH[1]-}"            # sequence number                       01
	t1="${tr%_$sq}"                     # trunk of base name w/o sequence       20170320-065042
	if [ "$t1" == "" ]; then t1="$tr"; fi

    [[ "$ex" =~ .*~([0-9]*)~ ]]
    bu="${BASH_REMATCH[1]-}"            # backup number                         3

	# normalised date             |-yy-------------------|        |-mm-----|         |-dd-----|         |-hh-----|         |-mi-----|         |-ss-----|         |-cs-----|
	[[ "${bn}0000000000000000" =~ ([1-9][0-9]{3}|[0-9]{2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2}).* ]]
	read x yy mm dd hh mi ss cs <<< ${BASH_REMATCH[@]//[!0-9]/}
	(( mm = 10#$mm < 1 ? 1 : 10#$mm ))
	(( dd = 10#$dd < 1 ? 1 : 10#$dd ))

	if (( 10#$yy>100 && 10#$yy<1900 )); then # work around date limitation # Todo: not accurate for leap years
		yoffset=$(( 2000 - 10#$yy ))
		yy=2000
	fi

	if $( date --version >/dev/null 2>&1 ) ; then # GNU 'date'
		read yy mm dd hh mi ss <<< $( date +"%Y %m %d %H %M %S" -d "$yy-1-1 +$(( 10#$mm-1 )) months +$(( 10#$dd-1 )) days +$hh hours +$mi minutes +$ss seconds" )
	else                                          # Mac OS 'date'
		read yy mm dd hh mi ss <<< $( date -j -v+$(( 10#$mm-1 ))m -v+$(( 10#$dd-1 ))d -v+${hh}H -v+${mi}M -v+${ss}S "01010000${yy}.00" +"%Y %m %d %H %M %S" )
	fi

	yy=$(( yy - yoffset ))
	yy=${yy: -4:4}

    if [[ ${CENTISECOND-0} != 15 ]]; then 
        enum -1 DIRECTORY BASENAME TRUNK TRUNK1 EXTENSION EXTENSION1 SEQUENCE BACKUP YEAR MONTH DAY HOUR MINUTE SECOND CENTISECOND 
    #   enum -1 DN        BN       TR    T1     EX        E1         SQ       BU     YY   MM    DD  HH   MI     SS     CS         
    fi

    unset REPLY
	#// ((DEBUG)) && set -x
    REPLY[DIRECTORY]="$dn"
    REPLY[BASENAME]="$bn"
    REPLY[TRUNK]="$tr"
    REPLY[TRUNK1]="$t1"
    REPLY[EXTENSION]="$ex"
    REPLY[EXTENSION1]="$e1"
    REPLY[SEQUENCE]="${sq:-00}"
    REPLY[BACKUP]="${bu:-00}"
    REPLY[YEAR]="$yy"
    REPLY[MONTH]="$mm"
    REPLY[DAY]="$dd"
    REPLY[HOUR]="$hh"
    REPLY[MINUTE]="$mi"
    REPLY[SECOND]="$ss"
    REPLY[CENTISECOND]="$cs"
	#// ((DEBUG)) && set +x

	#printDebugArr "${REPLY[@]}"
}



#===============================================================================
# NAME
#	photo_sort
#
# SYNOPSIS
#	photo_sort SOURCE_DIR DESTINATION_DIR REGULAR_EXPRESSION [MESSAGE]
#
# DESCRIPTION
#	This moves files that match the REGULAR_EXPRESSION from the SOURCE_DIR and
#	its subdirectories to the temporary directory (defined by global DIR_TMP).
#	From there it moves images and their side-car files to the DESTINATION_DIR,
#	based on the EXIF information of the images.
#
# OPTIONS
#	SOURCE_DIR          source directory of images and side-cars
#	DESTINATION_DIR     destination directory, subdirectories will be created
#	REGULAR_EXPRESSION  file name extensions, as RegExp suitable for `find`
#	MESSAGE             optional message, displayed in verbose or debug mode
#
# ENVIRONMENT
#	DEBUG    0: no 1: debug output
#	DIR_TMP  path to temporary directory
#
# EXAMPLES
#	photo_sort ~/Pictures/INBOX ~/Pictures/review "gif|jpg|png" "Sort images"
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.210111===

function photo_sort() { # SOURCE_DIR DESTINATION_DIR REGULAR_EXPRESSION [MESSAGE]
	printDebug "${FUNCNAME}( $@ )"
	local _from="$1" _to="$2" _regex="$3" _info="${4-} "

	printVerbose "Next step is: $_info."
	(($DEBUG)) && pause - "${_info}"

	printInfo "$_info(in $( realpath $_from) ) ..."
	photo_move "$_from" "$DIR_TMP" "$_regex" "$_info"

	pushd "$_from" >/dev/null
	#todo if [[ $CORRECTTIM == 1 ]] ; then $CMD_correcttim "${DIR_TMP%/}" ; fi
	#todo if [[ $TRASHDUPES == 1 ]] ; then $CMD_trashdupes "${DIR_TMP%/}" "${_to%/}" ; fi
	#*## Use for dry-run: exif_sort_images_and_sidecars_time_frame -n "${DIR_TMP%/}" "${_to%/}"
	exif_sort_images_and_sidecars_time_frame "${DIR_TMP%/}" "${_to%/}"
	photo_trash_duplicates "$_to"
	popd >/dev/null
}



#===============================================================================
# NAME
#	photo_trash
#
# SYNOPSIS
#	photo_trash FILENAME [REASON]
#
# DESCRIPTION
#	Move FILENAME to the trash and log this in a logfile. 
#
# OPTIONS
#	FILENAME	Input filename
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.210101===

function photo_trash() { # FILE [REASON]
	printDebug "${FUNCNAME}( $@ )"
	local file="$1" reason=" ${2-}"
	printToLog "Moved$reason to trash: $file"
	#// mv ${DEBUG:+"-v"} "$file" ${DIR_RCY%/}/ 2>/dev/null
	mv "$file" ${DIR_RCY%/}/ 2>/dev/null
}



#===============================================================================
# NAME
#	photo_trash_duplicate
#
# SYNOPSIS
#	photo_trash_duplicate FILE FILE
#
# DESCRIPTION
#	Binary compare both given files and trash the second one if they are
#	identical. This returs '1' if files differ and '0' if they were identical.
#
# OPTIONS
#	FILE	Input filenames
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.210102===

function photo_trash_duplicate() { # FILE FILE
	printDebug "${FUNCNAME}( $@ )"
	local f1 f2 return=1
	f1="$( realpath "$1" )"
	f2="$( realpath "$2" )"

	if [ -f "$f1" ] && [ -f "$f2" ] && [ "$f1" != "$f2" ]; then
		if $( cmp --silent "$f1" "$f2" ) ; then
			photo_trash "$f2" "duplicate"
			return=0
		fi
	fi

	return $return
}



#===============================================================================
# NAME
#	photo_trash_duplicates
#
# SYNOPSIS
#	photo_trash_duplicates DIRECTORY
#
# DESCRIPTION
#	Use fdupes (see https://github.com/adrianlopezroche/fdupes)
#	(download at brew.sh) 
#
# OPTIONS
#	DIRECTORY
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.210117===
#! fdupes: could not chdir to Photos Library.photoslibrary

function photo_trash_duplicates() { # DIRECTORY
	printDebug "${FUNCNAME}( $@ )"
	if [[ ${DEBUG:-0} == 0 ]]; then
		fdupes -AdNnqr -o name -l $LOGFILE $( realpath -q "$@" ) >/dev/null 2>/dev/null 
	else
		fdupes -AdNnr -o name -l $LOGFILE $( realpath -q "$@" )
	fi

	return
}



################################################################################
# make functions globally available
# TODO

if [[ "${photo_DEVELOP:-0}" == "0" ]]; then
	readonly MAC
	readonly LNX
	readonly WIN
fi

# ! Do not remove or alter these last lines:
photo_lib_loaded=1; ((DEBUG)) && echo "]"
((photo_DEVELOP)) || readonly photo_lib_loaded
return 0

################################################################################
# END
################################################################################