#!/bin/bash
#
# NAME
#	merge-gpx.bash - merge multiple GPX files into one
# 
# SYNOPSIS
#	merge-gpx.bash FILE1 FILE2 ...
#
# DESCRIPTION
#	Brain-dead merge of GPX files. Removing all headers and trailers. Output
#   goes to stdout.
#
# AUTHOR
#	@author     Andreas Tusche
#	@copyright  (c) 2017, Andreas Tusche 
#	@package    antu-photo
#	@version    $Revision: 0.0 $
#	@(#) $Id: . Exp $
#
# when       who  what
# 2017-04-19 AnTu created

echo '
<?xml version="1.0" encoding="utf-8"?>
<gpx version="1.0" xmlns="http://www.topografix.com/GPX/1/0" xsi:schemaLocation="http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd">
'
awk '
    /<gpx |<\/gpx|\<\?xml / {next}
    /creator=|version=|xmlns=|xmlns:|\.xsd|xsi=|xsi:/ {next}
    /<metadata>/,/<\/metadata>/ {next}
    {print}
' $@
echo '</gpx>
'
