#!/bin/bash
#
# NAME
#	photo-explain-times.bash - explain output of photo-check-times.bash
# 
# SYNOPSIS
#	photo-check-times.bash | photo-explain-times.bash 
#   photo-explain-times.bash FILENAME
#
# DESRIPTION
#	Input is a comma-separated list of times as seconds since 1970-Jan-01
#	00:00:00.
#		SourceFile minDateLong minDate CreateDate DateTimeOriginal ModifyDate\
#		FileModifyDate FileInodeChangeDate FileAccessDate
#
#	Output is a comma-separated list of times as seconds of differences from the
#	minDate
#		minDateLong minDate ∆CreateDate ∆DateTimeOriginal ∆ModifyDate\
#		∆FileModifyDate ∆FileInodeChangeDate ∆FileAccessDate SourceFile
#
# AUTHOR
#	@author     Andreas Tusche
#	@copyright  (c) 2017, Andreas Tusche 
#	@package    antu-photo
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
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
