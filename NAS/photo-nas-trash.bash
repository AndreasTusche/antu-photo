#!/bin/bash
# finds duplicates and suggests to move them to a trash dir
#
# to be run on NAS

# --- nothing beyond this line needs configuration -----------------------------
source "antu-photo.cfg" 2>/dev/null

RMT_SRC="XXX_JPG"

cd "$RMT_PIC"
cat "${RMT_SRC%/}/"[12][90][0-9][0-9]"/md5sum.txt" "${RMT_ORG%/}/"[12][90][0-9][0-9]"/md5sum.txt" |#
grep -v "@" |#
sort > all_md5sum.txt

uniq -D -w 32 all_md5sum.txt |#
sort -r |
awk '
# list all but one duplicates
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
	print "    mv \"" file "\" \"'${RMT_RCY%/}/'\""
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

echo " Please now run trash-duplicates.sh to trash duplicates"

