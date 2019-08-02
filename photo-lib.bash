#
# NAME
#   photo-lib.bash - Library of common functions for bash scripts
#
# SYNOPSIS
#   source photo-lib.bash
#
# DESCRIPTION
#	This library defines following simple bash functions:
#	- printDebug
#	- printError
#	- printToLog
#	- printWarn
#
# AUTHOR
# @author     Andreas Tusche    <antu-photo@andreas-tusche.de>
# @copyright  (c) 2018, Andreas Tusche <www.andreas-tusche.de>
# @package    antu-photo
# @version    $Revision: 0.0 $
# @(#) $Id: . Exp $
#
# when       who  what
# 2018-12-30 AnTu created
# 2019-08-02 AnTu export functions to call this file only once

(($DEBUG)) && echo "[sourced $( readlink -f "$BASH_SOURCE" )]"

# coloured error message
function printDebug {
	(($DEBUG)) && echo -e "\033[01;35mDEBUG:\033[00;35m ${@}\033[0m" >&2
}

function printError {
	echo -e "\033[01;31mERROR:\033[00;31m ${@}\033[0m" >&2
}

function printInfo {
	(($DEBUG)) || (($VERBOSE)) && echo -e "\033[01;32mINFO: \033[00;32m ${@}\033[0m" >&2
}

function printToLog {
	printDebug ${@}
	date +"%F %X%t${@}" >>${LOGFILE}
}

function printWarn {
	echo -e "\033[01;33mWARN: \033[00;33m ${@}\033[0m" >&2
}


# make functions globally available
export -f printDebug
export -f printError
export -f printInfo
export -f printToLog
export -f printWarn

# Do not remove or alter this last line:
export PHOTO_LIB_DONE=1