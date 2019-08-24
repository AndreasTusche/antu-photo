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

# --- nothing beyond this line needs configuration -----------------------------
if [ "$ANTU_PHOTO_CFG_DONE" != "1" ] ; then # read the configuration file(s)
	source "./antu-photo.cfg" 2>/dev/null
fi

for file in ${RMT_ERR%/}/*.*; do
	#  "${file}"       # full file name with path              /path1/path2/20170320-065042_1.jpg.~3~
	dn="${file%/*}"    # directory name                        /path1/path2
	fn="${file##*/}"   # full file name                        20170320-065042_1.jpg.~3~
	b0="${fn%%.~*}"    # file name without numbering           20170320-065042_1.jpg
	ex="${b0#*.}"      # extension                             jpg
	b1="${b0%%.*}"     # file base name (w/o extension)        20170320-065042_1
	bn="${b1%%_*}"     # file base name (w/o sequence number)  20170320-065042
	yy="${fn:0:4}"     # year                                  2017
	mm="${fn:4:2}"     # month                                 03
	dd="${fn:6:2}"     # day                                   20
	echo "---------------------"
	for f in ${file} ${RMT_EDT%/}/${yy}/${yy}-${mm}-${dd}/${bn}* ${RMT_ORG%/}/${yy}/${yy}-${mm}-${dd}/${bn}*; do 
		if [[ -e $f ]]; then
			#   "${f}"           # full file name with path              /path1/path2/20170320-065042_1.jpg.~3~
			fn1="${f##*/}"       # full file name                        20170320-065042_1.jpg.~3~
			b01="${fn1%%.~*}"    # file name without numbering           20170320-065042_1.jpg
			ex1="${b01#*.}"      # extension                             jpg
			mv --backup=numbered -v ${f} ${RMT_SRC%/}/${bn}.${ex1}
		fi
	done
done

# Rename backup-style filenames, if any
for f in "${RMT_SRC%/}"/*.~*; do
	if [[ -e $f ]]; then
		n=${f%~*}
		e=${f#*.}
		mv -n ${DEBUG:+"-v"} "${f}" "${f%%.*}_${n#*~}.${e%.*}"
	fi
done
for f in "${RMT_SRC%/}"/*_[0-9].*; do
	if [[ -e $f ]]; then
		mv -n ${DEBUG:+"-v"} "${f}" "${f%_*}_0${f#*_}"
	fi
done

