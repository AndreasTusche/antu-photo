#!/bin/bash
#
# NAME
# photo-fix-times.bash - fix photos with illogical time stamps
#
# SYNOPSIS
# photo-fix-times.bash [DIRNAME]
#
# DESCRIPTION
# Uses ExifTool to identify the following timestamps. It is expected that
# they are identical or increasing in this order. If this is not the case, the
# timestamps are set to the found minimum.
#  CreateDate ≤ DateTimeOriginal ≤ ModifyDate ≤ FileModifyDate
#  ≤ FileInodeChangeDate ≤ FileAccessDate
#
# If a GPS timestamp exists, it is trusted and the CreateDate and
# DateTimeOriginal values for minutes and seconds are set to those of the GPS
#   timestamp if they were not already identical.
#
# FILES
# Uses exiftool (http://www.sno.phy.queensu.ca/~phil/exiftool/)
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
# 2017-04-18 AnTu created

# config
DEBUG=0 # no debug output (0), somewhat verbose (1), more verbose (2)

# --- nothing beyond this line needs configuration -----------------------------
DIRNAME="$( readlink -f "${1:-$(pwd)}" )"

# I) Check for invalid GPS time-stamps and fix'em
# iPhone 5S delivers illegal date values; e.g.
# GPSDateTime                     : 2015:08:233 23:15:05.72Z
# Warning: PrintConv GPSDateTime: Day '233' out of range 1..31
echo "... checking GPS times"

IFS=,
exiftool --ext DS_Store --ext localized -i SYMLINKS -csv -m -progress: -q -r \
	-if '$gpsdatetime' -GPSDateTime \
	"${DIRNAME%/}" | awk -v DEBUG=$DEBUG '
    BEGIN {
   FS  = "[,: ]"
   OFS = ","
  }
        $4>31 {
                if (DEBUG) print "DEBUG: Wrong GPS time found: " $0 > "/dev/stderr"
                t=mktime($2" 1 "$4" "$5" "$6" "$7)
                print $1, strftime("%Y:%m:%d",t), strftime("%H:%M:",t)$7
            }
' | while read file date time
do
	exiftool --ext avi --ext bmp --ext moi --ext mpg --ext mts \
		-m -overwrite_original_in_place -q \
		-GPSDateStamp="$date" -GPSDateTime="$date $time" "$file"
done


# II) check other timestamps
echo "... checking time stamps"

exiftool -csv -d "%s" -f -i SYMLINKS -m -progress: -q -r \
	-GPSDateTime -CreateDate -DateTimeOriginal -ModifyDate -FileModifyDate -FileInodeChangeDate -FileAccessDate \
	"${DIRNAME%/}" | awk -v DEBUG=$DEBUG '
     BEGIN {
       FS  = ","
       OFS = ","
       MAX = 99999999999 # Wed 5138-Nov-16 10:46:39
                F_GPSDateTime         = 2
                F_CreateDate          = 3
                F_DateTimeOriginal    = 4
                F_ModifyDate          = 5
                F_FileModifyDate      = 6
                F_FileInodeChangeDate = 7
                F_FileAccessDate      = 8
      }

     # first line in CSV
     NR==1 && /^SourceFile/ { next }

     # replace exiftool text output by numbers where necessary
     {
            if (DEBUG>1) print "DEBUG: " $0 > "/dev/stderr"
      file = $1
      gsub(/\-/,MAX)
      gsub(/0000:00:00 00:00:00/,"0")
            GPStime_found = 0
     }

     # always trust GPS time but as the time-zone is usually different to the
        # other time-stamps only use the minutes and seconds, if needed

     0 < $F_GPSDateTime && $F_GPSDateTime < MAX && \
        ( $F_GPSDateTime != $F_CreateDate || $F_GPSDateTime != $F_DateTimeOriginal ) {
            GPSdate=strftime("%Y %m %d", $F_GPSDateTime)
            GPSminutes=strftime("%M", $F_GPSDateTime)
            GPSseconds=strftime("%S", $F_GPSDateTime)
            GPStime_found = 1
            if (DEBUG) print "DEBUG: GPS minutes:seconds = " GPSminutes ":" GPSseconds " (" file ")" > "/dev/stderr"
     }

     # check correct order of time-stamps, allow 2 seconds offset

     $F_CreateDate          > $F_DateTimeOriginal    + 2 || \
        $F_CreateDate          > $F_ModifyDate          + 2 || \
        $F_CreateDate          > $F_FileModifyDate      + 2 || \
        $F_CreateDate          > $F_FileInodeChangeDate + 2 || \
        $F_CreateDate          > $F_FileAccessDate      + 2 || \
        $F_DateTimeOriginal    > $F_ModifyDate          + 2 || \
        $F_DateTimeOriginal    > $F_FileModifyDate      + 2 || \
        $F_DateTimeOriginal    > $F_FileInodeChangeDate + 2 || \
        $F_DateTimeOriginal    > $F_FileAccessDate      + 2 || \
        $F_ModifyDate          > $F_FileModifyDate      + 2 || \
        $F_ModifyDate          > $F_FileInodeChangeDate + 2 || \
        $F_ModifyDate          > $F_FileAccessDate      + 2 || \
        $F_FileModifyDate      > $F_FileInodeChangeDate + 2 || \
        $F_FileModifyDate      > $F_FileAccessDate      + 2 || \
        $F_FileInodeChangeDate > $F_FileAccessDate      + 2 {
      m = MAX
      for (i=2; i<=NF; i++) {
       if ($i>0) {
        m = ( m<$i ? m : $i)
       }
      }
            if (GPStime_found==1) {
                if (DEBUG) print "DEBUG: min(Time) (1) = " strftime("%Y %m %d %H %M %S", m) > "/dev/stderr"

                MINminutes=strftime("%M", m)

                if (GPSminutes > 45 && MINminutes < 15 ) {
                    GPSminutes -= 60
                } else if (MINminutes > 45 && GPSminutes < 15 ) {
                    GPSminutes += 60
                }

                m = mktime( GPSdate " " strftime("%H ", m) GPSminutes " " GPSseconds)

                if (DEBUG) print "DEBUG: min(Time) (2) = " strftime("%Y %m %d %H %M %S", m) > "/dev/stderr"
            }
      $1 = file OFS strftime("%Y:%m:%d %H:%M:%S", m)
      print
     }
' | while read file mindate x
do
	(($DEBUG)) && echo "DEBUG: $file  to  $mindate"
	exiftool --ext avi --ext bmp --ext moi --ext mpg --ext mts \
		-m -overwrite_original_in_place -q \
		-AllDates="$mindate" -SonyDateTime="$mindate" -IFD1:ModifyDate="$mindate" -FileModifyDate="$mindate" \
		$file
done
