#!/bin/bash
#
# creates md5sum checksums for each file in the Pictures subdirectories
#
# to be run on NAS
#
# AUTHOR
#	@author     Andreas Tusche    <antu-photo@andreas-tusche.de>
#	@copyright  (c) 2019, Andreas Tusche <www.andreas-tusche.de>
#	@package    antu-photo
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# when       who  what
# ---------- ---- --------------------------------------------------------------
# 2019-01-01 AnTu created


#!#####################
echo "needs rewrite" #!
exit 1               #!
#!#####################


# --- nothing beyond this line needs configuration -----------------------------
if [ "$ANTU_PHOTO_CFG_DONE" != "1" ] ; then # read the configuration file(s)
	source "antu-photo.cfg" 2>/dev/null
fi

for p in ${LOC_ORG%/} ${LOC_EDT%/} ${LOC_SRC%/} ${LOC_SRC%/}_RAW ${LOC_SRC%/}_JPG ; do
	if [[ -e ${p} ]]; then
		echo "... md5sum for $p"
		find $p -type f -not -path "*/@*" -not -path "*/[12][09][0-9][0-9]/*" -not -name ".DS_Store" -not -name "md5sum.txt" -exec md5sum {} \;	>${p%/}/md5sum.txt

		for d in ${p%/}/[12][09][0-9][0-9]/; do
			if [[ -e $d ]]; then
				echo "... md5sum for $d"
				find $d -type f -not -path "*/@*" -not -name ".DS_Store" -not -name "md5sum.txt" -exec md5sum {} \;	>${d%/}/md5sum.txt
			fi
		done

	fi
done
