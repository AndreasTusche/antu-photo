#!/bin/bash
#
# NAME
#   photo-wake-nas.bash - Send wake-on-LAN to NAS
#
# SYNOPSIS
#   photo-wake-nas.bash
#
# DESCRIPTION
#	Sends the wake-on-LAN magic packet to a MAC adress which has to be
#	configured in the source code of this script or in a antu-photo.cfg file.
#
# FILES
#   wakeonlan - can be installed from Homebrew: 'brew install wakeonlan'
#
# AUTHOR
#	@author     Andreas Tusche    <antu-photo@andreas-tusche.de>
#	@copyright  (c) 2018-2019, Andreas Tusche <www.andreas-tusche.de>
#	@package    antu-photo
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# when       who  what
# ---------- ---- --------------------------------------------------------------
# 2018-12-30 AnTu created



#!#####################
echo "needs rewrite" #!
exit 1               #!
#!#####################



################################################################################
# config
################################################################################

DEBUG=${DEBUG:-1}                       # 0: do 1: do not print debug messages
                                        # 2: bash verbose, 3: bash xtrace
										# 9: bash noexec

# ~~~ remove after development ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
# ~~~ 

((DEBUG)) && clear

# preliminary print functions, may be replaced by those from lib_common.bash
printDebug() { ((DEBUG)) && echo -e "$(date +'%Y-%m-%d %T') \033[1;35mDEBUG  :\033[0;35m ${@}\033[0m" ; }
printError() {              echo -e "$(date +'%Y-%m-%d %T') \033[1;31mERROR  :\033[0;31m ${@}\033[0m" ; }



#-------------------------------------------------------------------------------
# path to this script
#-------------------------------------------------------------------------------

# --- see https://stackoverflow.com/questions/59895/
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
	DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
	SOURCE="$(readlink "$SOURCE")"
	[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
# ---

readonly _THIS=$(basename "$SOURCE")   # the file name of this script 
readonly _THIS_DIR="$DIR"              # the directory of this script
unset DIR SOURCE
printDebug "_THIS     = $_THIS"
printDebug "_THIS_DIR = $_THIS_DIR"



#-------------------------------------------------------------------------------
# load config file
#-------------------------------------------------------------------------------

for d in "$_THIS_DIR" ~/.config/antu-photo ~ . ; do
	source "$d/.antu-photo.cfg" 2>/dev/null || \
	source "$d/antu-photo.cfg"  2>/dev/null
done
((ANTU_PHOTO_CFG_LOADED)) || printError "No config file antu-photo.cfg was not found" || exit 1



#-------------------------------------------------------------------------------
# load some function libraries
#-------------------------------------------------------------------------------

source "$_THIS_DIR/lib_common.bash"
((common_lib_loaded)) || printError "Library $_THIS_DIR/lib_common.bash was not found." || exit 1

source "$LIB_antu_photo"
((photo_lib_loaded)) || printError "Library $LIB_antu_photo was not found." || exit 1



#-------------------------------------------------------------------------------
# check prerequisites
#-------------------------------------------------------------------------------

# TODO: check wakeonlan

################################################################################
# MAIN
################################################################################

# Check for NAS directory and wake up the NAS, if needed

if [[ ! -e "$NAS_MNT" ]]; then

	# wake on lan if NAS MAC address is not available in network
	ARP_MAC=${NAS_MAC//:0/:}; ARP_MAC=${ARP_MAC//00/0} # arp uses truncated MAC address
	if [[ ! $( arp -a | grep -i $ARP_MAC ) ]] ; then
		
		# find the network's broadcast address from `ifconfig` output, e.g.
		#	inet 192.168.42.42 netmask 0xffffff00
		#	inet 192.168.42.42 netmask 0xffffff00 broadcast 192.168.42.255
		if [[ "${NAS_BRD-}" == "" ]]; then
			NAS_BRD=$( ifconfig | awk '
				/broadcast/ { for (i=1;i<=NF;i++) if ($i~"broadcast") print $(i+1); exit } 
				/^[ \t]+inet [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ && ! /127.0.0.1/ { split($2,ip,"."); print ip[1]"."ip[2]"."ip[3]".255" }
				' )
 		fi

		# check if wakeonlan tool is installed
		WAKEONLAN=$(which wakeonlan) || WAKEONLAN="/usr/local/bin/wakeonlan"
		[ -e "$WAKEONLAN" ] || {
			printError  "wakeonlan not found."
			printError2 "You may install 'wakeonlan' as follows:"
			printError2 "    brew install wakeonlan"
			exit 1
		}
		
		# Wake On LAN and wait for the NAS to start up
		$WAKEONLAN -i $NAS_BRD -p $NAS_PRT $NAS_MAC
		printDebug "Waiting $(( NAS_SEC / 2 )) seconds before checking NAS"
		(( sec = ( NAS_SEC - NAS_SEC % 2 ) / 2 ))
		until test $((sec--)) -eq 0; do printf "%3d\r" $sec; sleep 1; done
	fi

	open -g "$NAS_URL" # open via finder also creates correct mount-point under /Volumes
	# todo replace by user accessible mount point, e.g.:
	# mkdir -p ~/NAS_Pictures
	# mount_afp $NAS_URL ~/NAS_Pictures

	# check every 2 sec if mount directory became available
	(( sec = NAS_SEC - NAS_SEC % 2 )) # ensure even number
	until test $(( sec = sec - 2 )) -eq 0 -o -d "${NAS_MNT%/}" ; do printf "%3d\r" $sec; sleep 2; done

	if [[ ! -e "$NAS_MNT" ]]; then
		printError "The Directory $NAS_MNT was not found on the NAS $NAS_URL after $NAS_SEC seconds."
		exit 1
	fi
fi
printToLog "The NAS directory $NAS_MNT is available."
