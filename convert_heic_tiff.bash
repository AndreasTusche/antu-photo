#
# convert HEIC image to TIFF and preserve EXIF information
# needs Imagemagick :: brew install imagemagick
# needs ExifTool    :: brew install exiftool

# need 8-bit sRGB LSB zip to work with DxO PhotoLab
# -colorspace sRGB -compress zip -depth 8 -endian LSB

# todo: batch convert
# todo: it's upside down, correct it  -orientation=1

# 2020-11-22 AnTu created

convert_heic_tiff () {
    magick $1 -colorspace sRGB -compress zip -depth 8 -endian LSB ${1%.heic}.tiff
    exiftool -tagsfromfile $1 ${1%.heic}.tiff
}
