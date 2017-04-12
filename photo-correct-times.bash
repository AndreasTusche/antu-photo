#!/bin/bash
# photo-correct-times.bash - create a list of commands to correct date and time stamps
#
# Input is a comma-separated list of times as seconds since 1970-Jan-01 01:00:00
# SourceFile minDateLong minDate CreateDate DateTimeOriginal ModifyDate FileModifyDate FileInodeChangeDate FileAccessDate
# Only the first and third entry (SourceFile and minDate) are actually used
#
# USAGE
#   photo-correct-times.bash FILENAME
#	photo-check-times.bash | photo-correct-times.bash
# or to directly execute
#   photo-correct-times.bash FILENAME | bash
#	photo-check-times.bash | photo-correct-times.bash | bash
#
# when       who  what
# 2017-04-08 AnTu initial release

awk '
	BEGIN {FS=","}
	/image files read/ {next}
	/^SourceFile/ {next}
	{
		# correct times in image
		dt=strftime("%Y:%m:%d %H:%M:%S",$3)
		printf "exiftool --ext avi --ext bmp --ext moi --ext mpg --ext mts -m -overwrite_original_in_place -q -CreateDate=\"%s\" -DateTimeOriginal=\"%s\" -SonyDateTime=\"%s\" -ModifyDate=\"%s\" -FileModifyDate=\"%s\" %s\n", dt, dt, dt, dt, dt, $1
	}
' ${1:-}
