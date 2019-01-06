#!/bin/bash
#
# NAME
#   photo-restore-original.bash - restore from "_original" files as by exiftool
# 
# SYNOPSIS
#   photo-restore-original.bash DIRECORY
#
# DESCRIPTION
#   This automates the maintenance of the "_original" files created by exiftool.
#   It has no effect on files without an "_original" copy. This restores the
#   files from their original copies by renaming the "_original" files to
#   replace the edited versions in a directory and all its subdirectories.
#
# AUTHOR
# @author     Andreas Tusche
# @copyright  (c) 2017, Andreas Tusche 
# @package    antu-photo
# @version    $Revision: 0.0 $
# @(#) $Id: . Exp $
#
# when       who  what
# 2017-04-08 AnTu created

#DIRNAME="${1:-$( readlink -f "${1:-$(pwd)}" )}"
DIRNAME="${1:-$(pwd)}"

exiftool -i SYMLINKS -q -r -restore_original "$DIRNAME"
find "$DIRNAME" -type f -name "*_original" | while read f ; do mv "$f" "${f%%_original}" ; done
