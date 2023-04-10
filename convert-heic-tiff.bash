#!/bin/bash
#
# converts one or all HEIC images in current directory to TIFF and preserve EXIF information
# needs Imagemagick :: brew install imagemagick
# needs ExifTool    :: brew install exiftool

# DxO PhotoLab can only read TIFF with 8-bit or 16-bit sRGB LSB zip
# HEIC has a colour depth of 16 bit
# -colorspace sRGB -compress zip -depth 16 -endian LSB

# 2020-11-22 AnTu created

function convert_heic_tiff () {
    out=$(sed 's/\.HEIC$/.tiff/i' <<< "$1")
    magick "$1" -auto-orient -colorspace sRGB -compress zip -depth 16 -endian LSB "${out}"
    exiftool -overwrite_original -tagsfromfile "$1" --orientation "${out}"
}

if [[ "$1" == "" ]]; then
    for f in *.[Hh][Ee][Ii][Cc]; do
        convert_heic_tiff ${f}
    done
else
    convert_heic_tiff "$1"
fi
