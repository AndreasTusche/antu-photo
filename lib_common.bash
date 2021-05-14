#
# -*- mode: bash; tab-width: 4 -*-
################################################################################
# lib_common - Library of common functions
#
# @author     Andreas Tusche <lib_common@andreas-tusche.de>
# @copyright  Andreas Tusche <www.andreas-tusche.de>
# @package    antu::bash_libraries
# @version    $Revision: 7.2.12 $
# @(#) $Id: lib_common.sh,v 7.2 2020/06/07 AnTu Exp $
#
#===============================================================================
#
# NAME
#
#	lib_common - a bash functions library
#
# SYNOPSIS
#
#	source lib_common.sh [--help]
#
# DESCRIPTION
#
#	This library provides a collection of functions that are common to a
#	number of scripts and don't fit into one of the other libraries.
#
#	abspath            - return absolute path
#	checkBin           - check file exists and is executable
#	checkPath          - check if the path exists
#	debugFunctionCalls - show stack trace of function calls
#	die                - terminate the script
#	enum               - enumerate a list of strings and create variables
#	isAbsolutePath     - check if the path begins with '/'
#	isEmptyDirectory   - check if directory is empty
#	isNumber           - check if string matches a number
#	isRelativePath     - check if the path does not begin with '/'
#	isRootUser         - check if current user is the root user
#	logDebug           - output a string to stderr
#	logError           - output a string to stderr
#	logInfo            - output a string to stderr
#	logWarning         - output a string to stderr
#	pause              - wait for user reaction or timeout
#	printDebug         - print coloured debug message, if in DEBUG mode
#	printDebug2        - print indented coloured debug message, if in DEBUG mode
#	printDebugVar      - print the name and value of a variable, if in DEBUG mode
#	printError         - print coloured error message 
#	printError2        - print indented coloured error message
#	printFolded        - print text with left or right margin
#	printInfo          - print coloured message
#	printInfo2         - print indented coloured message 
#	printStep          - print progress information and end that line with "done"
#	printTemplate      - print a template string with variables replaced by values
#	printTemplateFile  - print a template file with variables replaced by values
#	printVerbose       - print coloured message, if in VERBOSE mode
#	printVerbose2      - print indented coloured message, if in VERBOSE mode
#	printWarning       - print coloured warning message to stderr
#	printWarning2      - print indented coloured warning message to stderr
#	rotateLog          - rotate log files and keep n copies
#	strRLE             - run-length encode string
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#===============================================================================
#
# when       who  what
# ---------- ---- --------------------------------------------------------------
# 2008-07-03 AnTu initial release
# 2008-07-16 AnTu minor changes due to library updates
# 2009-01-30 AnTu new printTemplate(), printTemplateFile()
# 2009-02-04 AnTu new strRLE(), new option -p to enum()
# 2009-07-28 AnTu new printError(), printWarning(), printStep
# 2010-09-23 AnTu new printDebug()
# 2012-11-20 AnTu new rotateLog()
# 2013-09-18 AnTu corrected display of help text
# 2013-10-21 AnTu rotateLog now allows spaces in file-name or path
# 2013-10-22 AnTu new printDebug2(), printError2(), printWarning2()
# 2014-11-13 AnTu new log*() functions
# 2020-06-07 AnTu new printFolded(), now called by all other print*()
# 2020-12-04 AnTu new check*(), is*() functions, better debugging options
################################################################################

DEBUG=${DEBUG-''}						# 0: do not 1: do print debug messages
                                        # 2: bash verbose, 3: bash xtrace
										# 9: bash noexec

(( ${common_lib_loaded:-0} )) && return 0 # load me only once
((DEBUG)) && echo -n "[ . $BASH_SOURCE "

################################################################################
# config for this library
################################################################################

common_DEVELOP=1                        # special settings for while developing
common_ERROR_TRAP=0                     # dump function calls in case of error
common_MY_VERSION='$Revision: 7.2.12 $' # version of this library



################################################################################
# all arguments are handled by the calling script, but in case help is needed
################################################################################

case "${@:-}" in
	--help)
		awk 'BEGIN{l=""} /^# NAME/,/^#===/ {print l; if (/^#===/) exit; sub(/^# ?/,"");gsub(/\t/,"    ");l=$0}' "$BASH_SOURCE"
		exit 0
		;;
esac



################################################################################
# global variables
################################################################################

# Global shell behaviour
set -o nounset                          # Used variables MUST be initialized.
set -o errtrace                         # Traces error in function & co.
set -o functrace                        # Traps inherited by functions
set -o pipefail                         # Exit on errors in pipe
set +o posix                            # disable POSIX

((DEBUG>1)) && set -o verbose; ((DEBUG<2)) && set +o verbose
((DEBUG>2)) && set -o xtrace;  ((DEBUG<3)) && set +o xtrace
((DEBUG>8)) && set -o noexec;  ((DEBUG<9)) && set +o noexec

((DEBUG)) && VERBOSE=1 || VERBOSE=${VERBOSE:-$DEBUG}

((common_ERROR_TRAP)) && trap 'debugFunctionCalls $?' ERR   # dump function calls in case of error

# general global constants
readonly UNKNOWN=-1                     # for variables with unknown value (use with care)

# bash prompt for trace (set -x)
export PS4='\033[0;33m+(${0##*/}:${LINENO}):\033[0;34;1m${FUNCNAME[0]:+${FUNCNAME[0]}():}\033[0m '

# use error codes beween 3 and 125 (the others are reserved by bash)
readonly ERR_OK=0             # normal exit status, no error
readonly ERR_NOERR=0          # normal exit status, no error
readonly ERR_INFO=10          # use 10-39 for INFORMATIONS (no action needed)
readonly ERR_NOTHING_TO_DO=11          # Info there is nothing to do for this script
readonly ERR_USAGE=12                  # After showing usage
readonly ERR_WARN=40          # use 40-69 for WARNINGS (no immediate action)
readonly ERR_ARGS=41                   # Warning, no or wrong number of arguments
readonly ERR_NOT_IMPLEMENTED=42        # Warning, feature not (yet) implemented
readonly ERR_UNKNOWN_ARGUMENT=43       # Warning, unknown or not well-formed argument
readonly ERR_UNKNOWN_OPTION=44         # Warning, unknown or not well-formed option
readonly ERR_OTHER_INSTANCE=45         # Warning, other instance of script is running
readonly ERR_ERROR=50         # use 50-59 for ERRORS (needs immediate investigation)
readonly ERR_FILE_NOT_FOUND=51         # Error, could not find file
readonly ERR_DIR_NOT_FOUND=52          # Error, could not find directory
readonly ERR_LIB_NOT_FOUND=53          # Error, could not find library
readonly ERR_NOT_READABLE=54           # Error, file has no read permisson 
readonly ERR_NOT_WRITEABLE=55          # Error, file has no write permission
readonly ERR_NOT_EXECUTABLE=56         # Error, file has no execution permission
readonly ERR_CRASH=60         # use 60-63 for CRASHES (needs immediate recovery action)
# 64 to 78 are reserved for system program exit status codes (see sysexits.h)
# readonly ERR_USAGE=64                # command line usage error
# readonly ERR_DATAERR=65              # data format error
# readonly ERR_NOINPUT=66              # cannot open input
# readonly ERR_NOUSER=67               # addressee unknown
# readonly ERR_NOHOST=68               # host name unknown
# readonly ERR_UNAVAILABLE=69          # service unavailable
# readonly ERR_SOFTWARE=70             # internal software error
# readonly ERR_OSERR=71                # system error (e.g., can't fork)
# readonly ERR_OSFILE=72               # critical OS file missing
# readonly ERR_CANTCREAT=73            # can't create (user) output file
# readonly ERR_IOERR=74                # input/output error
# readonly ERR_TEMPFAIL=75             # temp failure; user is invited to retry
# readonly ERR_PROTOCOL=76             # remote error in protocol
# readonly ERR_NOPERM=77               # permission denied
# readonly ERR_CONFIG=78               # configuration error



################################################################################
# Functions
################################################################################

#===============================================================================
# NAME
#	checkBin - check file exists and is executable
#
# SYNOPSIS
#	checkBin FILE
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.201204===

function checkBin() {
	printDebug "${FUNCNAME}( $@ )"
	local _bin="$1" _path

	_path=$( command -v "$_bin" )       # check if binary is available

	if [ $? -ne 0 ]; then
		printError "Binary '$_bin' was not found."
		return $ERR_FILE_NOT_FOUND
	else
		[ -x "$_path" ] && return 0 	# check execute permission
		printError "Binary '$_bin' has no execute permission."
		return $ERR_NOT_EXECUTABLE
	fi

	printDebug "Binary '$_bin' found at '$_path' ."
	return $ERR_OK
}



#===============================================================================
# NAME
#	checkPath - check if the path exists
#
# SYNOPSIS
#	checkPath PATH
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.201204===

function checkPath() {
	printDebug "${FUNCNAME}( $@ )"
	[ -e "$1" ] && return 0
	((VERBOSE)) && printError "Path '$1' was not found."
	return $ERR_DIR_NOT_FOUND
}



#===============================================================================
# NAME
#	debugFunctionCalls - show stack trace of function calls
#
# SYNOPSIS
#	debugFunctionCalls STATUS
#
# DESCRIPTION
#
# OPTIONS
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.201204===

function debugFunctionCalls() {
	local _n="${#FUNCNAME[@]}"
	local _status="${1:-?}"
	local _msg="Script failed with status $_status. Trace:"

	# Starts to 1 to avoid THIS function name, and stops before the last one to avoid "main".
	for index in $( eval echo "{0..$((_n-2))}" ); do
		_msg="$_msg\n at ${BASH_SOURCE[$index+1]}:${BASH_LINENO[$index]}\t\tcalled\t#${FUNCNAME[$index]}"
	done
	printWarning "$_msg"
	return $ERR_OK
}



#==============================================================================
# NAME
#	die - terminate script
#
# SYNOPSIS
#	die [ERRORCODE [MESSAGE]]
#
# DESCRIPTION
#	This will terminate the running script
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.210513===

function die() { # [ERRORCODE [MESSAGE]]
	printDebug "${FUNCNAME}( $@ )"
	local err=${1-1}; 
	isNumber "$err" && shift || err=1
	[ -z ${1+x} ] || printError "$@"
	exit $err
}



#==============================================================================
# NAME
#	enum - enumerate a list of strings and create variables
#
# SYNOPSIS
#	enum [ -0 | -1 | -n NUMBER ] [-p PREFIX] LIST
#
# DESCRIPTION
#	This function walks through a list of strings and creates variables with
#	the those names. Each variable is assigned an integer value, starting from 0
#	or 1 or any given number and incrementing by one.
#
# OPTIONS
#	[ -0 | -1 | -n NUMBER ]
#		Define the number of the first element (0, 1, or NUMBER), 0 is the
#		default. This must be the first argument to the function.
#
#	[-p PREFIX]
#		Prefix the created variable names with PREFIX. Defaults to an
#		empty string. If used, this option must be after the -0, -1 or
#		-n option.
#
#	LIST
#		List of unique strings.
#
# DIAGNOSTICS
#	This function returns the next number following the last assigned value.
#
# EXAMPLE
#	enum ONE TWO THREE
#		This creates three variables, where $ONE is 0, $TWO is 1, and $THREE
#		is 2. The return value is 3.
#
#	enum -1 ONE TWO THREE
#		This creates three variables, where $ONE is 1, $TWO is 2, and $THREE
#		is 3. The return value is 4.
#
#	enum -n 42 ONE TWO THREE
#		This creates three variables, where $ONE is 42, $TWO is 43, and
#		$THREE is 44. The return value is 45.
#
#	enum -p var 0 8 15 42
#		This creates four variables, where $var0 is 0, $var8 is 1,
#		$var15 is 2, and $var42 is 3. The return value is 4.
#
#	enum -n 4711 -p my_ ONE TWO THREE
#		This creates three variables, where $my_ONE is 4711, $my_TWO is 4712,
#		and $my_THREE is 4713. The return value is 4714.
#
# GLOBAL VARIABLES SET
#	return                             # integer or string holding the result
#	and all elements of the LIST are turned into global variables as well
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.090204===

function enum { # [-0 | -1 | -n NUMBER] [-p PREFIX] ( LIST_OF_VARNAMES )
	printDebug "${FUNCNAME}( $@ )"
	local -i i
	local first=0 prefix=""

	case $1 in
		-0) first=0  ; shift ;;
		-1) first=1  ; shift ;;
		-n) first=$2 ; shift 2 ;;
	esac
	case $1 in
		-p) prefix=$2 ; shift 2 ;;
	esac

	for (( i=1; $i<=$#; i++ )) ; do
		eval ${prefix}${!i}=$(( $i + $first - 1 ))
		((DEBUG>1)) && printDebug "${FUNCNAME}: ${prefix}${!i} = $(( $i + $first - 1 ))"
	done

	return=$(( $i + $first - 1 ))
	return $return
}



#===============================================================================
# NAME
#	isAbsolutePath - check if the path begins with '/'
#
# SYNOPSIS
#	isAbsolutePath PATH
#
# DESCRIPTION
#	check if the path begins with '/'
#
# OPTIONS
#	PATH
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.201204===

function isAbsolutePath() {
	printDebug "${FUNCNAME}( $@ )"
	[[ "$1" =~ ^/.*$ ]]
}



#===============================================================================
# NAME
#	isEmptyDirectory - check if directory is empty
#
# SYNOPSIS
#	isEmptyDirectory PATH
#
# DESCRIPTION
#
# OPTIONS
#
# DIAGNOSTICS
#
# EXAMPLE
#
# GLOBAL VARIABLES
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.201204===

function isEmptyDirectory() {
	printDebug "${FUNCNAME}( $@ )"
	local _dir="${1:-}"
	[[ -n "$_dir" && -d "$_dir" && $( find "$_dir" -maxdepth 1 2>/dev/null | wc -l ) -eq 1 ]]
}



#===============================================================================
# NAME
#	isNumber - check if string matches a number
#
# SYNOPSIS
#	isNumber STRING
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.201204===

function isNumber() {
	printDebug "${FUNCNAME}( $@ )"
	[[ "$1" =~ ^[[:digit:]]+$ ]]
}



#===============================================================================
# NAME
#	isRelativePath - check if the path does not begin with '/'
#
# SYNOPSIS
#	isRelativePath PATH
#
# DESCRIPTION
#	check if the path does not begin with '/'
#
# OPTIONS
#	PATH
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.201204===

function isRelativePath() {
	printDebug "${FUNCNAME}( $@ )"
	[[ "$1" =~ ^[^/]*$ ]]
}



#===============================================================================
# NAME
#	isRootUser - check if current user is the root user
#
# SYNOPSIS
#	isRootUser
#
# DESCRIPTION
#
# OPTIONS
#
# DIAGNOSTICS
#
# EXAMPLE
#
# GLOBAL VARIABLES
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.201204===

function isRootUser() {
	printDebug "${FUNCNAME}( $@ )"
	[[ "$( whoami )" == "root" ]]
}



#===============================================================================
# ! DEPRECATED
#
# NAME
#	logDebug    - output a string to stderr
#	logError    - output a string to stderr
#	logWarning  - output a string to stderr
#	logInfo     - output a string to stderr
#
# SYNOPSIS
#	logDebug STRING
#	logErr STRING
#	logWarning STRING
#	logInfo STRING
#
# DESCRIPTION
#	These functions log the current time stamp and debug, error or warning
#	messages to stderr.
#
# OPTIONS
#	STRING  The string to be loged, prefixed by the current time and the
#	word DEBUG, ERROR or WARNING.
#
# EXAMPLE
#	logDebug   "HAL 9000 initialising."
#	logError   "Sorry Dave, I can't do that."
#	logWarning "The main antenna will fail in 42 hours."
#	logInfo    "All systems functioning in nominal parameters."
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.141113===
# TDOD: REWRITE or combine with print* functions

function _common_log {
	(($_logStep_len)) && echo ""
	if [[ ${#fileLog}>0 ]] ; then
		echo "$(date +'%Y-%m-%d %T') ${@}" | tee -a "${fileLog}" >&2
	else
		echo "$(date +'%Y-%m-%d %T') ${@}" >&2
	fi
}

function logDebug   { _common_log "DEBUG:   ${@}"; }
function logError   { _common_log "ERROR:   ${@}"; }
function logInfo    { _common_log "INFO:    ${@}"; }
function logWarning { _common_log "WARNING: ${@}"; }



#===============================================================================
# NAME
#	pause - Wait for user reaction or timeout
#
# SYNOPSIS
# 	pause [- | SECONDS] [PROMPT]
#
# DESCRIPTION
#	Wait for user reaction before continuing, optional time-out in seconds and
#	prompt.
#
# OPTIONS
#	SECONDS  seconds to wait, or "-" to use TMOUT or default value (42s)
#	PROMPT   output without a trailing newline before attempting to read
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.210514===
# ToDo: exit on letters 'q'(quit) 'n'(no) 'x'(exit)

function pause() { # [SECONDS [PROMPT]] 
	printDebug "${FUNCNAME}( $@ )"

	if [[ "${1:--}" == "-" ]]; then
		local _timeout=${TMOUT:-42}
	else
		local _timeout=${1:-${TMOUT:-42}} 
	fi
	((DEBUG)) && (( _timeout = 9 * _timeout + 42 ))

	echo -e "\033[01;30;103mPress any key to continue (${_timeout}s) Ctrl-C to stop)\033[01;05;30;103m:\033[0m"
	read -n1 -r -s -t ${_timeout} ${2:+"-p$2 "}
	echo
	return
}



#===============================================================================
# NAME
#	printDebug    - print coloured debug message, if in DEBUG mode
#	printDebug2   - print indented coloured debug message, if in DEBUG mode
#	printDebugVar - print the name and value of a variable, if in DEBUG mode
#	printError    - print coloured error message
#	printError2   - print indented coloured error message
#	printFolded   - print text with left or right margin
#	printInfo     - print coloured message
#	printInfo2    - print indented coloured message
#	printVerbose  - print coloured message, if in VERBOSE mode
#	printVerbose2 - print indented coloured message, if in VERBOSE mode
#	printWarning  - print coloured warning message
#	printWarning2 - print indented coloured warning message
#
# SYNOPSIS
#	printDebug    [options] STRING
#	printDebug2   [options] STRING
#	printDebugVar VARNAME
#	printError    [options] STRING
#	printError2   [options] STRING
#	printFolded   [options] STRING
#	printInfo     [options] STRING
#	printInfo2    [options] STRING
#	printVerbose  [options] STRING
#	printVerbose2 [options] STRING
#	printWarning  [options] STRING
#	printWarning2 [options] STRING
#
#	With options:
# 	[-1 FIRSTINDENT] [-c NONPRINTABLES] [-i INDENT] [-l LENGTH] [-w]
#
# DESCRIPTION
#	These functions print the current time stamp and debug, error or warning
#	messages in magenta, red or black on yellow respective to stderr.
#	Long messages will be folded and indented.
#	Further indented lines can be printed using the print*2() functions.
#	Use these funtions if the output is expected on a terminal window. For
#	logging purposes (using a log file) use the log*() functions instead.
#
# OPTIONS
#	STRING  The string to be printed, prefixed by the current time and the
#	word DEBUG, ERROR, INFO or WARNING.
#  VARNAME  The name of the variable (without leading '$', of course)
#   -1 FIRSTINDENT    - indent for first line
#   -c NONPRIINTABLES - number of nonprintables in first line ("\033[" is one char)
#   -i INDENT         - indent for 2nd and following lines
#   -l LENGTH         - max total line length for output messages
#   -w                - set LENGTH to terminal width
#
# GLOBAL VARIABLES
#	COLUMNS           - terminal width
#	INIT_TABS         - tabulator length
#
# EXAMPLE
#	printDebug   "HAL 9000 initialising."
#	printError   "Sorry Dave, I can't do that."
#	printWarning "The main antenna will fail in 42 hours."
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.201129===

function printFolded() {
	local C=0                             # number of nonprintables in first line
	local F=0                             # indent for first line
	local L=${COLUMNS:=$(tput cols)}      # max line length for output messages (including indent)
	local I=${INIT_TABS:=$(tput it)}      # indent for 2nd and following lines
	local COL n ROW s=""

	# ToDo: stop loop after e.g. option "--" and use remaining for message string
	for ((n=1; $n <= $# ; n++)) ; do
		case "${!n}" in
		--)         (( n++ )); s="$s ${!n}"; break ;;
		-1|--first) (( n++ )); (( F=0+${!n} )) ;;
		-c|--invis) (( n++ )); (( C+=${!n}  )) ;;
		-i|--left)  (( n++ )); (( I=0+${!n} )) ;;
		-l|--right) (( n++ )); (( L=0+${!n} )) ;;
		-w|--width) L=$(tput cols) ;; # terminal width
		*) s="$s${!n} ";;
		esac
	done

#	((common_DEVELOP)) && echo "         1         2         3         4         5         6         7         8"
#	((common_DEVELOP)) && echo "12345678901234567890123456789012345678901234567890123456789012345678901234567890"

	# TODO: find a better way for cursor position check
	# start a new line if cursor is not at the beginning of line
# 	IFS=';' read -sdR -p $'\E[6n' ROW COL 
#	((COL>1)) && echo

	# first line
	echo -e "$s" \
	| fold -sw$((L+C-F)) \
	| awk 'NR==1{for(i=1;i<'$F';i++) printf " "; print}'

	# subsequent lines
	((${#s}>L+C-F)) && echo -e "$s" \
	| fold -sw$((L+C-F)) \
	| awk 'NR>1{printf "%s", $0}' \
	| fold -sw$((L-I)) \
	| awk '{for(i=1;i<'$I';i++) printf " "; print}'

	return 0
}

# ANSI colour codes: <esc>[Am or <esc>[A;Bm or or <esc>[A;B;Cm
# <esc> = \033
# A: style:       00 reset,  01 bold, 02 fg dim, 03 italic,  04 underline, 05 blink,    06 normal, 07 invers, 08 invisible 
# B: text color:  30 black,  31 red,  32 green,  33 yellow,  34 blue,      35 magenta,  36 cyan,   37 white,  38 terminal default
# B: bright text: 90 gray,   91 red,  92 green,  93 yellow,  94 blue,      95 magenta,  96 cyan,   97 white,  98 terminal default
# C: background:  40 black,  41 red,  42 green,  43 yellow,  44 blue,      45 magenta,  46 cyan,   47 white,  48 transparent
# C: bright bg:  100 gray,  101 red, 102 green, 103 yellow, 104 blue,     105 magenta, 106 cyan,  107 white, 108 transparent

function printDebug()    { ((DEBUG))   && printFolded -c 12 -i 30 "$(date +'%F %T') \033[1;35mDEBUG  :\033[0;35m" "${@}\033[0m" >&2 ; }
function printError()    {                printFolded -c 12 -i 30 "$(date +'%F %T') \033[1;91mERROR  :\033[0;91m" "${@}\033[0m" ; }
function printInfo()     {                printFolded -c 12 -i 30 "$(date +'%F %T') \033[1;32mINFO   :\033[0;32m" "${@}\033[0m" ; }
function printVerbose()  { ((VERBOSE)) && printFolded -c 12 -i 30 "$(date +'%F %T') \033[1;32mINFO   :\033[0;32m" "${@}\033[0m" >&2 ; }
function printWarning()  {                printFolded -c 12 -i 30 "$(date +'%F %T') \033[1;93mWARNING:\033[0;93m" "${@}\033[0m" ; }

function printDebug2()   { ((DEBUG))   && printFolded -c  9 -1 29 -i 30 "\033[0;35m" "${@}\033[0m" >&2 ; }
function printError2()   {                printFolded -c  9 -1 29 -i 30 "\033[0;91m" "${@}\033[0m" ; }
function printInfo2()    {                printFolded -c  9 -1 29 -i 30 "\033[0;32m" "${@}\033[0m" ; }
function printVerbose2() { ((VERBOSE)) && printFolded -c  9 -1 29 -i 30 "\033[0;32m" "${@}\033[0m" >&2 ; }
function printWarning2() {                printFolded -c  9 -1 29 -i 30 "\033[0;93m" "${@}\033[0m" ; }

function printDebugVar() {
	if [ -z ${1+x} ]; then
		printDebug "$1 is unset"  # won't come here if `set -o nounset`
	else
		printDebug "$1 = '${!1}'" # doesn't work for arrays # TODO find a way for arrays
	fi
}

function printToLog()    {
	printVerbose ${@}
	echo $(date +"%F %T%t") "${@}" >>"${LOGFILE}"
}

#===============================================================================
# ! DEPRECATED
#
# NAME
#	printStep - print one line of information or end that line with "done"
#
# SYNOPSIS
#	printStep BOOLDSTRING MESSAGESTRING
#	printStep [-n] {-d | done}
#
# DESCRIPTION
#	This function prints the first BOLDSTRING in bold and the MESSAGESTRING
#	in normal font. The output will NOT be terminated by a line feed.
#	The total length of the message is stored.
#	In case the BOLDSTRING equals "done", then the word "done" is printed in
#	green colour at the end of the line and terminated by a line feed.
#	If you want the word "done" to appear on a separate line then use the -n
#	option.
#
# OPTIONS
#	BOLDSTRING     The string to be printed in bold.
#	MESSAGESTRING  The message to be printed in normal font
#	done           The literal "done", makes the function to end the line.
#	-d             The literal "done", makes the function to end the line.
#	-n             Make the "done" appear on a separate line.
#
# EXAMPLE
#	printStep INFO Read the fantastic manual.
#	printStep done
#		This will result in the output
#		INFO: Read the fantastic manual                                ... done
#	where the word "INFO" is printed in bold.
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.131022===
# TODO: REWRITE

function printStep() {
	printDebug "${FUNCNAME}( $@ )"
	_printStep_len=${_printStep_len:-0} # init global var

	case "${1-}" in
		-n)
			_printStep_len= # null
			shift
			;;
	esac

	local bold="${1-}" ; shift
	local lenspc msg="${@-}"

	case "$bold" in
		-d|[Dd][Oo][Nn][Ee])
			msg="                                                                                "
			lenspc=$(( 70 - ${_printStep_len:-0} ))

			if (( $lenspc > 0 )) ; then
				echo -n "${msg:0:$lenspc}"
			else
				echo -en "\n${msg:0:70}"
			fi

			echo -e  "\033[01;32m ...\033[00;32m done\033[0m"
			_printStep_len= # null
			;;
		*)
			((_printStep_len)) && echo
			_printStep_len=$(( ${#bold} + ${#msg} + 2 ))
			echo -en "\033[01m${bold}\033[0m: $msg"
			;;
		esac
}



#===============================================================================
# NAME
#	printTemplate -  print a template string with variables replaced by values
#
# SYNOPSIS
#	printTemplate VARNAME
#
# DESCRIPTION
#	This function takes the string from $VARNAME and replaces all variables
#	within that string by their values. Unset variables are replaced by an
#	empty string.
#
#	Use this function for printing from templates.
#
# OPTIONS
#	VARNAME  A name of a variable that holds the template string.
#
# EXAMPLE
#	template='I am ${USER}. My favourite number is ${a[2]}.'
#	a=( 40 41 42 43 44 )
#	printTemplate template
#		This will print:
#		I am pgf. My favourite number is 42.'
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.090130===

function printTemplate { # TEMPLATE
	printDebug "${FUNCNAME}( $@ )"
	eval echo -e '"'"$( echo "${!1}" | sed 's/"/\\"/g' )"'"'
}



#===============================================================================
# NAME
#	printTemplateFile - print a template file with variables replaced by values
#
# SYNOPSIS
#	printTemplateFile FILENAME
#
# DESCRIPTION
#	This function takes the content from the file FILENAME and replaces all
#	variables by their values. Unset variables are replaced by an empty string.
#
#	Use this function for printing from templates.
#
# OPTIONS
#	FILENAME  A file name of a template file.
#
# EXAMPLE
#	echo 'I am ${USER}. My favourite number is ${a[2]}.' > template.txt
#	a=( 40 41 42 43 44 )
#	printTemplateFile template.txt
#		This will print:
#		I am pgf. My favourite number is 42.'
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.090130===

function printTemplateFile { # FILENAME
	printDebug "${FUNCNAME}( $@ )"
	eval echo -e '"'"$(sed 's/"/\\"/g' "$@")"'"'
}



#===============================================================================
# NAME
#	realpath - return absolute path
#
# SYNOPSIS
#	realpath PATH
#
# DESCRIPTION
#	Return the path with all symlinks resolved as encountered.
#====================================================================V.210103===

if ! $( which -s realpath ) ; then
	#* this function will only be defined, if the 'realpath' command is not
	#* found in the PATH

	function realpath() { # FILE
		printDebug "${FUNCNAME}( $@ )"
		perl -e 'use Cwd "abs_path";print abs_path(shift)' "$1"
	}

	# function realpath() {
	# 	printDebug "${FUNCNAME}( $@ )"
	# 	pushd . > /dev/null

	# 	if [ -d "$1" ]; then
	# 		cd "$1"
	# 		dirs -l +0
	# 	else
	# 		cd "$( dirname "$1" )"
	# 		cur_dir=$( dirs -l +0 )

	# 		if [ "$cur_dir" == "/" ]; then
	# 			echo "$cur_dir$( basename "$1")"
	# 		else
	# 			echo "$cur_dir/$( basename "$1" )"
	# 		fi
	# 	fi

	# 	popd > /dev/null
	# }
fi



#===============================================================================
# NAME
#	rotateLog - rotate log files and keep only some copies
#
# SYNOPSIS
#	rotateLog [FILE [NUMBER]]
#
# DESCRIPTION
#	This function keeps NUMBER previous copies of the given FILE. The
#	youngest file will get the extension ".01", the file prior to that
#	gets the extension ".02" and so on.
#
#	Don't confuse it with the time-based UNIX "rotatelogs" command.
#
# OPTIONS
#	FILE
#		The full path and file name of the log file to be rotated. If no
#		filename was given then use the file defined by the environment
#		variable LOGFILE.
#
#	NUMBER
#		Optionally define the number of the files to keep, the maximum
#		should not exceed 99. The default is 9.
#
# EXAMPLE
#	rotateLog /data/logs/my.log 3
#		This will keep /data/logs/my.log and /data/logs/my.log.{02,01}.
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.201213===

function rotateLog() { # FILE [NUMBER]
	printDebug "${FUNCNAME}( $@ )"
	local f="${1:-${LOGFILE}}" n=${2:-9}
	local fNew fOld fOlder fOldest

	if [[ "$f" == "" || ! -f "$f" ]]; then
		printDebug "Logfile '$f' not found."
		return $ERR_FILE_NOT_FOUND
	fi

	(( n = n > 1 ? n > 99 ? 99 : n : 9 )) # allow values 2-99, default 9
	printf -v fOldest "%s.%02d" "${f}" ${n}

	for (( i=(n-1); i>1; i-- )); do
		(( h = i - 1 , j = i + 1 ))
		printf -v fNew "%s.%02d" "${f}" ${h}
		printf -v fOld "%s.%02d" "${f}" ${i}
		printf -v fOlder "%s.%02d" "${f}" ${j}

		if [ -f "${fNew}" -a -f "${fOld}" ] ; then
			mv "${fOld}" "${fOlder}"
		fi
	done

	if [ -f "$f" ] ; then
		if [ -f "$f.01" ] ; then
			mv "${f}.01" "${f}.02"
		fi

		mv "${f}" "${f}.01"
	fi

	if [ -f "$fOldest" ] ; then
		find "${f%/*}" -maxdepth 1 -name "${f##*/}*" ! -name "$fOldest" ! -newer "$fOldest" -exec rm {} \;
	fi
}

#===============================================================================
# NAME
#	strRLE - run-length encode string
#
# SYNOPSIS
#	strRLE [-d DELIM] [-d DELIM2] STRING
#
# DESCRIPTION
#	For each char in the STRING, the number of succeeding occurrences are
#	counted. The char and the count are printed. separated by DELIM. Pairs
#	of chars and counts are separated by DELIM2.
#	Each space or tab in the input string is converted into "_" (underscore).
#
# OPTIONS
#	-d DELIM   First delimiter, defaults to " " (SPACE)
#	-d DELIM2  Second delimiter, defaults to " " (SPACE)
#	STRING     The string to encode. Use printable chars only.
#
# DIAGNOSTICS
#	This function returns the next number of char blocks.
#
# EXAMPLE
#	strRLE "strRLE "44444441"
#		This will print: 4 7 1 1 . The return value is 2.
#
#	strRLE -d , "Hello"
#		This will print: H,1,e,1,l,2,o,1,. The return value is 4.
#
#	strRLE -d "=" -d "&" "Hello mate"
#		This will print: H=1&e=1&l=2&o=1&_=1&m=1&a=1&t=1&e=1&. The
#		return value is 9.
#
# AUTHOR
#	Andreas Tusche <www.andreas-tusche.de>
#====================================================================V.090204===
# TODO: read input from pipe

function strRLE { # [-d DELIM] [-d DELIM2] STRING
	printDebug "${FUNCNAME}( $@ )"
	local c d1=' ' d2=' '
	local -a aC aN
	local -i i l n=0

	case $1 in -d) d1=$2 ; d2=$2 ; shift 2 ;; esac
	case $1 in -d)         d2=$2 ; shift 2 ;; esac

	aC[0]=''
	l=${#1}
	for ((i=0; i<l; i++)) ; do
		c=${1:$i:1}
		[[ $c != ${aC[$n]} ]] && (( n++ ))
		aC[$n]="$c"
		aN[$n]=$((aN[$n] + 1 ))
	done

	for (( i=1; i<=n ; i++ )) ; do
		echo -n "${aC[$i]/[	 ]/_}${d1}${aN[$i]}${d2}"
	done

	return $(( i-1 ))
}

################################################################################
# Cleanup and return
################################################################################

if [[ "${common_DEVELOP:-0}" == "0" ]]; then
	declare -fr abspath
	declare -fr checkBin           
	declare -fr checkPath          
	declare -fr debugFunctionCalls 
	declare -fr die
	declare -fr enum               
	declare -fr isAbsolutePath     
	declare -fr isEmptyDirectory   
	declare -fr isNumber           
	declare -fr isRelativePath     
	declare -fr isRootUser         
	declare -fr logDebug           
	declare -fr logError           
	declare -fr logInfo            
	declare -fr logWarning         
	declare -fr pause              
	declare -fr printDebug         
	declare -fr printDebug2        
	declare -fr printDebugVar      
	declare -fr printError         
	declare -fr printError2        
	declare -fr printFolded        
	declare -fr printInfo          
	declare -fr printInfo2         
	declare -fr printStep          
	declare -fr printTemplate      
	declare -fr printTemplateFile  
	declare -fr printVerbose       
	declare -fr printVerbose2      
	declare -fr printWarning       
	declare -fr printWarning2      
	declare -fr rotateLog          
	declare -fr strRLE             
fi

# Do not remove or alter the next line:
common_lib_loaded=1; ((DEBUG)) && echo "]"

((common_DEVELOP)) || readonly common_lib_loaded
return 0

################################################################################
# END
################################################################################
