#!/bin/bash
#
# NAME
# antu_extractphotolibrary.bash - retrieve photos from Apple Photo Libraries
#
# SYNOPSIS
# antu_extractphotolibrary.bash LIBRARY
#
# DESCRIPTION
#  * recursevly moves photos from  LIBRARY/Masters/ to ~/Pictures/
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
# 2015-11-05 AnTu initial version

DIR_PIC=~/Pictures/

# -------------------------------------
# MAIN
# -------------------------------------
if [ "$1" == "" ]; then exit ; fi

cd "$1"
find Masters -type f -exec mv -v --backup=t "{}" ${DIR_PIC} \;

for f in *.~*; do
	n=${f%~*}
	e=${f#*.}
	mv -n -v "${f}" "${f%%.*}_${n#*~}.${e%.*}"
done	

for f in *_[1-9].*; do
	cmp "${f}" "${f%_*}.${f##*.}" 2>/dev/null

	if [ $? == 0 ]; then
		rm "$f"
	fi

done
