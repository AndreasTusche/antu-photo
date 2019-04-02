#!/bin/bash
# creates md5sum checksums for each file in the Pictures subdirectories
#
# to be run on NAS

# --- nothing beyond this line needs configuration -----------------------------
source "antu-photo.cfg" 2>/dev/null

for d in ${RMT_ORG%/}/[12][09][0-9][0-9]/; do
	echo "... md5sum for $d"
	find $d -type f -not -path "*/@*" -not -name ".DS_Store" -not -name "md5sum.txt" -exec md5sum {} \;	>${d%/}/md5sum.txt
done

for d in ${RMT_SRC%/}/[12][09][0-9][0-9]/; do
	echo "... md5sum for $d"
	find $d -type f -not -path "*/@*" -not -name ".DS_Store" -not -name "md5sum.txt" -exec md5sum {} \;	>${d%/}/md5sum.txt
done

RMT_SRC="${RMT_PIC%/}/XXX_JPG"

for d in ${RMT_SRC%/}/[12][09][0-9][0-9]/; do
	echo "... md5sum for $d"
	find $d -type f -not -path "*/@*" -not -name ".DS_Store" -not -name "md5sum.txt" -exec md5sum {} \;	>${d%/}/md5sum.txt
done

