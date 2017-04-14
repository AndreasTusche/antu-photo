# AnTu-photo

AnTu-photo sorts pictures by time.

This is a quick wrapper around the [ExifTool by Phil Harvey](http://www.sno.phy.queensu.ca/~phil/exiftool/). It corrects the timestamps of pictures, if needed, and then sorts the files in a directory structure based on the creation time, like

    ~/Pictures/YYYY/YYYY-MM-DD/YYYYMMDD-hhmmss.jpg

It also brings some simple shell scripts which are more intuitive than the complex exiftool parameters.



## antu-sortphotos.bash

This moves

  * movies from     `~/Pictures/INBOX/` and subfolders to `~/Movies/yyyy/yyyy-mm-dd/`
  * movies from     `~/Movies/`                        to `~/Movies/yyyy/yyyy-mm-dd/`
  * raw images from `~/Pictures/INBOX/` and subfolders to `~/Pictures/RAW/yyyy/yyyy-mm-dd/`
  * edited images from `~/Pictures/INBOX/` and subfolders to `~/Pictures/edit/yyyy/yyyy-mm-dd/`
  * photos from     `~/Pictures/INBOX/` and subfolders to `~/Pictures/sorted/yyyy/yyyy-mm-dd/`

Movies are sorted first. They are recognised by their file extension:

    .3g2 .3gp .asf .avi .drc .flv .f4v .f4p .f4a .f4b .lrv .m4v .mkv .mov .qt
    .mp4 .m4p .moi .mod .mpg, .mp2 .mpeg .mpe .mpv .mpg .mpeg, .m2v .ogv .ogg
    .pgi .rm .rmvb .roq .svi .vob .webm .wmv .yuv

Raw images are recognised by their file extension:

    .3fr .3pr .ari .arw .bay .cap .ce1 .ce2 .cib .cmt .cr2 .craw .crw .dc2 .dcr
	.dcs .dng .eip .erf .exf .fff .fpx .gray .grey .gry .iiq .kc2 .kdc .kqp .lfr
	.mdc .mef .mfw .mos .mrw .ndd .nef .nop .nrw .nwb .olr .orf .pcd .pef .ptx
	.r3d .ra2 .raf .raw .rw2 .rwl .rwz .sd[01] .sr2 .srf .srw .st[45678] .stx
	.x3f .ycbcra

Edited images are recognised by their file extension:

    .afphoto .bmp .eps .pdf .psd .tif .tiff

Images and RAW images are renamed to `YYYYMMDD-hhmmss.xxx`, duplicates are not
kept but if two files were taken at the same second, the filename will be
suffixed with a an incremental number: `YYYYMMDD-hhmmss_n.xxx`.

In a second invocation, with option `--stage2`, they will be resorted

  * moves photos from     `~/Pictures/sorted/` and subfolders to `~/Pictures/yyyy/yyyy-mm-dd/`



## Helper Scripts


### photo-check-times.bash

identify photos with unlogical time stamps


###	photo-correct-times.bash

create a list of commands to correct date and time stamps


### photo-explain-times.bash

explain output of photo-check-times.bash


### photo-restore-original.bash

restore from `_original` files as by ExifTool


### photo-set-times.bash

set date and time to a fixed date


### photo-shift-times.bash

shift date and time by a fixed number of seconds


### photo-sort.bash

recursively rename and sort photos by creation date


## tested on

| OS            | bash      | perl      | ExifTool |
|---------------|-----------|-----------|----------|
| macOS 10.12.4 | 3.2.57(1) | (v5.18.2) | 10.48    |

