## antu-sortphotos.bash

A quick wrapper around the 'exiftool' tool for my preferred directory

  * moves movies from     `~/Pictures/INBOX/` and subfolders to `~/Movies/yyyy/yyyy-mm-dd/`
  * moves movies from     `~/Movies/`                        to `~/Movies/yyyy/yyyy-mm-dd/`
  * moves raw images from `~/Pictures/INBOX/` and subfolders to `~/Pictures/RAW/yyyy/yyyy-mm-dd/`
  * moves edited images from `~/Pictures/INBOX/` and subfolders to `~/Pictures/edit/yyyy/yyyy-mm-dd/`
  * moves photos from     `~/Pictures/INBOX/` and subfolders to `~/Pictures/sorted/yyyy/yyyy-mm-dd/`

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
