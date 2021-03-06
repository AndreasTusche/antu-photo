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
# @author     Andreas Tusche    <antu-photo@andreas-tusche.de>
# @copyright  (c) 2018, Andreas Tusche <www.andreas-tusche.de>
# @package    antu-photo
# @version    $Revision: 0.0 $
# @(#) $Id: . Exp $
#

# default configs
NAS_URL=""  # from config file         # The NAS URL should read "afp://User:Password@Server/Directory"
NAS_MNT=/Volumes/Pictures              # Mount point for NAS pictures directory
NAS_BRD=""  # auto detect              # Wake-On-LAN Network Broadcast Address (e.g. 255.255.255.255) keep empty for auto-detect
NAS_MAC=""  # from config file         # the NAS MAC Address
NAS_PRT=9                              # Wake-On-LAN PortNumber (e.g. 9)
NAS_SEC=124                            # seconds after wake up the NAS should be available

# --- nothing beyond this line needs configuration -----------------------------
for d in "${0%/*}" ~ . ; do source "$d/.antu-photo.cfg" 2>/dev/null || source "$d/antu-photo.cfg" 2>/dev/null; done
source "$LIB_antu_photo"

# === MAIN ===

# Check for NAS directory and wake up the NAS, if needed

if [[ ! -e "$NAS_MNT" ]]; then

	# wake on lan if NAS MAC address is not available in network
	ARP_MAC=${NAS_MAC//:0/:}; ARP_MAC=${ARP_MAC//00/0} # arp uses truncated MAC address
	if [[ ! $( arp -a | grep -i $ARP_MAC ) ]] ; then
		
		# find the network's broadcast address from `ifconfig` output, e.g.
		#	inet 192.168.42.42 netmask 0xffffff00
		#	inet 192.168.42.42 netmask 0xffffff00 broadcast 192.168.42.255
		if [[ "${NAS_BRD}" == "" ]]; then
			NAS_BRD=$( ifconfig | awk '
				/broadcast/ { for (i=1;i<=NF;i++) if ($i~"broadcast") print $(i+1); exit } 
				/^[ \t]+inet [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ && ! /127.0.0.1/ { split($2,ip,"."); print ip[1]"."ip[2]"."ip[3]".255" }
				' )
 		fi

		# check if wakeonlan tool is installed
		WAKEONLAN=$(which wakeonlan) || WAKEONLAN="/usr/local/bin/wakeonlan"
		[ -e "$WAKEONLAN" ] || {
			printError "wakeonlan not found."
			echo "You may install 'wakeonlan' as follows:"
			echo "    brew install wakeonlan"
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
	
	printToLog "The NAS directory $NAS_MNT is available."
fi
