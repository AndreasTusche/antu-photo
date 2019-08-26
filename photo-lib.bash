#
# NAME
#   photo-lib.bash - Library of common functions for bash scripts
#
# SYNOPSIS
#   source photo-lib.bash
#
# DESCRIPTION
#	This library defines following bash functions:
#	- pause
#	- photo_align_backup_file_names
#	- printDebug
#	- printDebug2
#	- printError
#	- printToLog
#	- printWarn
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
# 2018-12-30 AnTu created
# 2019-08-02 AnTu export functions to call this file only once
# 2019-08-23 AnTu moved photo_align_backup_file_names here
# 2019-08-26 AnTu added pause and printDebug2

(($DEBUG)) && echo "[sourced $( readlink -f "$BASH_SOURCE" )]"



# Wait for user reaction before continuing, optional time-out in seconds and prompt
# pause [SECONDS [PROMPT]]
function pause {
	echo -e "\033[01;30;103mPress any key to continue ("${1:+"${1}s "}"Ctrl-C to stop)\033[01;05;30;103m:\033[0m"
	read -n1 -r -s ${1:+"-t $1"} ${2:+"-p $2"}
	echo
}



# NAME
#	photo_align_backup_file_names
#
# SYNOPSIS
#	photo_align_backup_file_names DIRECTORY
#
# DESCRIPTION
#	Rename file names from `mv` backup-style to filename with sequence number.
#		"filename.ext.~1~" to "filename_01.ext"
#	This is not recursively entering any subdirectory.
#
function photo_align_backup_file_names {
	printDebug "${FUNCNAME}($@)"

	DIR="$1" # expects Directory Path
	[ ! -d "$DIR" ] && {
		printError "${FUNCNAME}(): 1st parameter must be a directory\n$DIR is not a directory"
		exit 1;
	}

	# Rename backup-style filenames, if any
	for file in "${DIR%/}"/*.~*; do
		if [[ -e $file ]]; then
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
			nn=$( [ $n1 -lt 10 ] && echo "0${n1}" || echo "${n1}" )    # at least two digit numbering
			
			# increment new sequence number until it doesn't clash with existing files
			while [ -e "${DIR%/}/${bn}_${nn}.${ex}" ]; do
				n1=$(( n1 + 1 ))
				nn=$( [ $n1 -lt 10 ] && echo "0${n1}" || echo "${n1}" )
			done

			mv -n ${DEBUG:+"-v"} "${file}" "${DIR%/}/${bn}_${nn}.${ex}"
		fi
	done

	# convert single digit sequence numbers to two digit
	for f in *_[0-9].*; do
		if [[ -e $f ]]; then
			mv -n ${DEBUG:+"-v"} "${f}" "${f%_*}_0${f#*_}"
		fi
	done
}

# coloured messages
function printDebug {
	(($DEBUG)) && echo -e "\033[01;35mDEBUG:\033[00;35m ${@}\033[0m" >&2
}
function printDebug2 {
	(($DEBUG>1)) && echo -e "\033[01;35mDEBUG:\033[00;35m ${@}\033[0m" >&2
}

function printError {
	echo -e "\033[01;31mERROR:\033[00;31m ${@}\033[0m" >&2
}

function printInfo {
	(($DEBUG)) || (($VERBOSE)) && echo -e "\033[01;32mINFO: \033[00;32m ${@}\033[0m" >&2
}

function printToLog {
	(($DEBUG)) && echo -e "\033[01;35mLOG:  \033[00;35m ${@}\033[0m" >&2
	date +"%F %X%t${@}" >>${LOGFILE}
}

function printWarn {
	echo -e "\033[01;33mWARN: \033[00;33m ${@}\033[0m" >&2
}


# make functions globally available
export -f pause
export -f photo_align_backup_file_names
export -f printDebug
export -f printDebug2
export -f printError
export -f printInfo
export -f printToLog
export -f printWarn

# Do not remove or alter this last line:
export PHOTO_LIB_DONE=1