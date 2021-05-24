#!/bin/bash
#
# NAME
#	antu-sortphotos-stage2.bash - move pre-sorted photos to daily folders
#
# SYNOPSIS
#	antu-sortphotos-stage2.bash
#
# DESCRIPTION
#	This is just calling
#		antu-sortphotos.bash --stage2
#
#	Pictures already sorted by `antu-sortphotos.bash` will be resorted:
#	* photos        from     ~/Pictures/sorted/ and subfolders
#	                to       ~/Pictures/YYYY/YYYY-MM-DD/
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
# 2019-08-01 AnTu initial version


#!#####################
echo "needs rewrite" #!
exit 1               #!
#!#####################


${0%/*}/antu-sortphotos.bash --stage2
