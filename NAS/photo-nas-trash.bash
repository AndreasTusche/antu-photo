#!/bin/bash
# finds duplicates and suggests to move them to a trash dir
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

cd "$LOC_PIC"
cat "${LOC_SRC%/}/md5sum.txt" "${LOC_SRC%/}/"[12][90][0-9][0-9]"/md5sum.txt" "${LOC_ORG%/}/"[12][90][0-9][0-9]"/md5sum.txt" |#
grep -v "@" |#
sort > all_md5sum.txt

uniq -D -w 32 all_md5sum.txt |#
sort -r |
awk '
# list all but one duplicates
BEGIN {
	print "#!/bin/bash"
	print "l=( $( wc -l $0) )"
	print "n=$(( ( ${l[0]} - 3 ) / 6 ))"
}
$1==hash {
	line=$0                               # The whole line from md5sum file
	hash=$1                               # The md5 hash of this line
	$1=""                               
	sub(/^[ \t\r\n]+/, "", $0)
	file=$0                               # The file of this line
	ydir=$0                               # the directory up to the year
	sub(/[0-9-]{10}\/.*/, "", ydir) 
	efil=file                             # The file with escaped slashes
	gsub(/\//, "\\/", efil)
	print "if [[ -e  \"" prev "\" && -e \"" file "\" ]]; then"
	print "    echo $(( ++i )) of $n:" file
	print "    mv -v \"" file "\" \"'${LOC_RCY%/}/'\""
	print "    sed -i \"/" efil "/d\" all_md5sum.txt"
	print "    sed -i \"/" efil "/d\" \"" ydir "md5sum.txt\""
	print "fi"
	next}
{	hash=$1
	$1=""
	sub(/^[ \t\r\n]+/, "", $0)
	prev=$0
}
' >trash-duplicates.sh

echo "Now, please run trash-duplicates.sh to trash duplicates"

