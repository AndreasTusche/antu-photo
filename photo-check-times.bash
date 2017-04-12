#!/bin/bash
# photo-check-times.bash - identify photos with unlogical time stamps
# 
# Uses EXIF-Tool to identify the following timestamps. It is expected that they
# are identical or increasing in this order. If this is not the case, the file-
# name and its timestamps are returned.
# CreateDate ≤ DateTimeOriginal ≤ ModifyDate ≤ FileModifyDate ≤ FileInodeChangeDate ≤ FileAccessDate
#
# Ouput a space-separated list of with times as seconds since 1 Jan 01:00:00 1970
# SourceFile minDateLong minDate CreateDate DateTimeOriginal ModifyDate FileModifyDate FileInodeChangeDate FileAccessDate
#
# The output 
# USAGE
#   photo-check-times.bash [DIRNAME]
#
# when       who  what
# 2017-04-07 AnTu initial release

DIRNAME="$( readlink -f "${1:-$(pwd)}" )"

# output field numbers:                             2           3                 4           5               6                    7
exiftool -csv -d "%s" -f -i SYMLINKS -progress: -r -CreateDate -DateTimeOriginal -ModifyDate -FileModifyDate -FileInodeChangeDate -FileAccessDate "${DIRNAME%/}" 2>/dev/null | awk '
	BEGIN {
			FS  = ","
			OFS = ","
			MIN = 99999999999 # Wed 5138-Nov-16 10:46:39
		}
	/image files read/ {next}
	/^SourceFile/ {
		$1 = $1 OFS "minDateLong" OFS "minDate"
		print
		next
	}
	{
		file = $1
		gsub(/\-/,MIN) 
		gsub(/0000:00:00 00:00:00/,"0")
	}
	$2>$3 || $2>$4 || $2>$5+10 || $2>$6+10 || $2>$7+10 || $3>$4 || $3>$5+10 || $3>$6+10 || $3>$7+10 || $4>$5+10 || $4>$6+10 || $4>$7+10 || $5>$6 || $5>$7 || $6>$7 {
		m = MIN
		for (i=2; i<=NF; i++) {
			if ($i>0) {
				m = ( m<$i ? m : $i)
			}
		}
		$1 = "\"" file "\"" OFS strftime("%F-%T", m) OFS m
		print
	}
'

# example entries found in photo files:
#
# [Composite]     DateTimeCreated                 : 2009:01:01 14:21:09
# [Composite]     DigitalCreationDateTime         : 2009:01:03 12:44:45+01:00
# [Composite]     GPSDateTime                     : 2016-08-18T12:45:02+0000
# [Composite]     RunTimeSincePowerUp             : 9 days 9:47:31
# [Composite]     SubSecCreateDate                : 2013-12-26T15:50:43+0100
# [Composite]     SubSecDateTimeOriginal          : 2013-12-26T15:50:43+0100
# [EXIF:ExifIFD]  CreateDate                      : 1999-12-31T14:36:30+0100
# [EXIF:ExifIFD]  DateTimeOriginal                : 1999-12-31T14:36:30+0100
# [EXIF:ExifIFD]  SubSecTimeDigitized             : 00
# [EXIF:ExifIFD]  SubSecTimeOriginal              : 00
# [EXIF:GPS]      GPSDateStamp                    : 2014:11:23
# [EXIF:GPS]      GPSTimeStamp                    : 09:41:04.51
# [EXIF:IFD0]     ModifyDate                      : 1999-12-31T14:36:30+0100
# [EXIF]          CreateDate                      : 2025:07:11 13:54:08
# [EXIF]          ExposureTime                    : 1/125
# [EXIF]          GPSTimeStamp                    : 11:18:30.76
# [EXIF]          ModifyDate                      : 2007:08:03 13:04:09
# [EXIF]          SubSecTimeDigitized             : 096
# [EXIF]          SubSecTimeOriginal              : 096
# [File:System]   FileAccessDate                  : 2017-04-07T20:19:12+0200
# [File:System]   FileInodeChangeDate             : 2015-11-15T21:00:30+0100
# [File:System]   FileModifyDate                  : 1999-12-31T15:36:30+0100
# [File]          FileAccessDate                  : 2017:04:09 15:26:03+02:00
# [File]          FileInodeChangeDate             : 2017:03:27 23:09:58+02:00
# [File]          FileModifyDate                  : 2008:05:21 20:45:34+02:00
# [FlashPix]      ExtensionCreateDate             : 2003:03:29 17:47:50
# [FlashPix]      ExtensionModifyDate             : 2003:03:29 17:47:50
# [H264]          DateTimeOriginal                : 2015-08-25T10:23:52+0100
# [ICC_Profile:ICC-header] ProfileDateTime        : 2003-07-01T00:00:00+0200
# [ICC_Profile]   ProfileDateTime                 : 1998:02:09 06:49:00
# [IPTC]          DateCreated                     : 2009:01:03
# [IPTC]          DigitalCreationDate             : 2009:01:03
# [IPTC]          DigitalCreationTime             : 12:44:45+01:00
# [IPTC]          TimeCreated                     : 14:21:09
# [MakerNotes]    DateStampMode                   : Off
# [MakerNotes]    RunTimeEpoch                    : 0
# [MakerNotes]    RunTimeFlags                    : Valid
# [MakerNotes]    RunTimeScale                    : 1000000000
# [MakerNotes]    RunTimeValue                    : 812851892115041
# [MakerNotes]    SelfTimer                       : Off
# [MakerNotes]    SelfTimer2                      : 0
# [MakerNotes]    TargetExposureTime              : 1/60
# [PNG]           ModifyDate                      : 2001-07-16T08:14:36+0200
# [QuickTime:Track1] TrackCreateDate              : 2015-08-26T16:57:43+0200
# [QuickTime:Track2] MediaCreateDate              : 2015-08-26T16:57:43+0200
# [QuickTime]     ContentCreateDate               : 2015-08-26T09:57:42-0700
# [QuickTime]     ContentCreateDate-deu           : 2015-08-26T09:57:42-0700
# [QuickTime]     CreateDate                      : 2015-08-26T16:57:43+0200
# [QuickTime]     CreationDate                    : 2015-08-26T09:57:42-0700
# [QuickTime]     CreationDate-deu-DE             : 2015-08-26T09:57:42-0700
# [XMP:XMP-microsoft] DateAcquired                : 2015-03-26T13:07:25+0100
# [XMP:XMP-photoshop] DateCreated                 : 2017-01-05T15:01:01+0100
# [XMP]           CreateDate                      : 2008:04:06 17:29:13+02:00
# [XMP]           DateAcquired                    : 2014:09:03 09:06:58.222
# [XMP]           DateCreated                     : 2009:01:01 14:21:09
# [XMP]           DateTimeDigitized               : 2008:04:06 16:15:33+02:00
# [XMP]           MetadataDate                    : 2010:09:10 18:20:31+02:00
