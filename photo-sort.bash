#!/bin/bash
# photo-sort.bash - recursivly rename and sort photos by creation date
# 
# USAGE
#   photo-sort.bash INDIR OUTDIR
#
# 	INDIR  defaults to "in"  directory under the present working directory
# 	OUTDIR defaults to "out" directory under the present working directory
#
# when       who  what
# 2017-04-09 AnTu initial release

INDIR="$(  readlink -f "${1:-$(pwd)/in}" )"
OUTDIR="$( readlink -f "${2:-${INDIR%/}/../out}" )"

exiftool -ext "*" --ext DS_Store --ext localized -i SYMLINKS -m -r -v "-FileName<FileModifyDate" "-FileName<ModifyDate" "-FileName<DateTimeOriginal" "-FileName<CreateDate" -d "${OUTDIR%/}/%Y/%Y-%m-%d/%Y%m%d-%H%M%S%%+c.%%le" "${INDIR}"
