#/bin/bash
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
# 2019-08-18 AnTu created
# 2019-08-24 AnTu corrected paths


#!#####################
echo "needs rewrite" #!
exit 1               #!
#!#####################


# --- nothing beyond this line needs configuration -----------------------------
(($ANTU_PHOTO_CFG_DONE)) || source "./antu-photo.cfg"
(($PHOTO_LIB_DONE))      || source "$LIB_antu_photo"

for file in ${LOC_ERR%/}/*.*; do
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
	echo "---------------------"
#	for f in ${file} ${LOC_EDT%/}/${yy}/${yy}-${mm}-${dd}/${bn}* ${LOC_ORG%/}/${yy}/${yy}-${mm}-${dd}/${bn}* ; do 
	for f in ${file} ${LOC_EDT%/}/${yy}/${yy}-${mm}-${dd}/${bn}* ; do 
		if [[ -e $f ]]; then
			#   "${f}"           # full file name with path              /path1/path2/20170320-065042_1.jpg.~3~
			fn1="${f##*/}"       # full file name                        20170320-065042_1.jpg.~3~
			b01="${fn1%%.~*}"    # file name without numbering           20170320-065042_1.jpg
			ex1="${b01#*.}"      # extension                             jpg
			mv --backup=numbered -v ${f} ${LOC_SRC%/}/${bn}.${ex1}
		fi
	done
done

photo_align_backup_file_names "${LOC_SRC%/}"
