#!/bin/bash
# photo-explain-times.bash - explain output of photo-check-times.bash
# 
# Input is a comma-separated list of times as seconds since 1 Jan 01:00:00 1970
# SourceFile minDateLong minDate CreateDate DateTimeOriginal ModifyDate FileModifyDate FileInodeChangeDate FileAccessDate
#
# Output is a comma-separated list of times as seconds of differences from the minDate
# minDateLong minDate ∆CreateDate ∆DateTimeOriginal ∆ModifyDate ∆FileModifyDate ∆FileInodeChangeDate ∆FileAccessDate SourceFile
#
# USAGE
#   photo-check-times.bash | photo-explain-times.bash 
#   photo-explain-times.bash FILENAME
#
# when       who  what
# 2017-04-08 AnTu initial release

awk '
	BEGIN {FS=","; OFS=","}
	/image files read/ {next}
	/^SourceFile/ {next}
	{ gsub(/99999999999/,$3) } 
	{ printf "%s,%10d,%10d,%10d,%10d,%10d,%10d, %s\n", $2, $4-$3, $5-$3, $6-$3, $7-$3, $8-$3, $9-$3, $1 }
' ${1:-}
