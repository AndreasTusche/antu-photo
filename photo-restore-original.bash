#!/bin/bash
# photo-restore-original.bash - set times according to output of photo-check-times.bash output
# 
# This automates the maintenance of the "_original" files created by exiftool.
# It has no effect on files without an "_original" copy. This restores the
# files from their original copies by renaming the "_original" files to replace
# the edited versions in a directory and all its subdirectories.
#
# USAGE
#   photo-restore-original.bash DIRECORY
#
# when       who  what
# 2017-04-08 AnTu initial release

DIRNAME="${1:-$( readlink -f "${1:-$(pwd)}" )}"

exiftool -i SYMLINKS -q -r -restore_original "$DIRNAME"
find "$DIRNAME" -type f -name "*_original" | while read f ; do mv "$f" "${f%%_original}" ; done
