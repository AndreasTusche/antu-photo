# AnTu-photo

AnTu-photo sorts pictures by time.

This is a quick wrapper around the [ExifTool by Phil Harvey](http://www.sno.phy.queensu.ca/~phil/exiftool/). It corrects the timestamps of pictures, if needed, and then sorts the files in a directory structure based on the creation time, like

    ~/Pictures/YYYY/YYYY-MM-DD/YYYYMMDD-hhmmss.jpg

It also brings some simple shell scripts which are more intuitive than the complex exiftool parameters.

The usual workflow is like this:

1) copy new images to INBOX
2) check for corrupted GPS Date Stamps and fix
3) check for corrupted other times (e.g. CreateDate > ModifyDate) and set them to the minimum date found
4) rename by time and frame number (if exists)
5) sort files into a directory structure based on the date
    - at this point the newly processed pictures are in `~/Pictures/sorted/yyyy/yyyy-mm-dd/` for review. Here we may revisit the gps.pgx file and the use `photo-set.gps` to set the GPS coordinates of the other files.
6) sort files into the final directory structure based on the date (using option `--stage2`)

## antu-sortphotos

This moves

  * movies from        `~/Pictures/INBOX/` and subfolders to `~/Movies/yyyy/yyyy-mm-dd/`
  * movies from        `~/Movies/`                        to `~/Movies/yyyy/yyyy-mm-dd/`
  * raw images from    `~/Pictures/INBOX/` and subfolders to `~/Pictures/RAW/yyyy/yyyy-mm-dd/`
  * edited images from `~/Pictures/INBOX/` and subfolders to `~/Pictures/edit/yyyy/yyyy-mm-dd/`
  * photos from        `~/Pictures/INBOX/` and subfolders to `~/Pictures/sorted/yyyy/yyyy-mm-dd/`

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

Images and RAW images are renamed to `YYYYMMDD-hhmmss.xxx`, duplicates are not kept but if two files were taken at the same second, the filename will be suffixed with a an incremental number: `YYYYMMDD-hhmmss_n.xxx`.

In a second invocation, with option `--stage2`, they will be resorted

  * moves photos from     `~/Pictures/sorted/` and subfolders to `~/Pictures/yyyy/yyyy-mm-dd/`



## Helper Scripts

### photo-extract-gps

This extracts GPS geo-location information from files in the given directory and subfolders and writes the result in GPX format to stdout.

    photo-extract-gps.bash DIRNAME


### photo-fix-times

Uses ExifTool to identify the following timestamps. It is expected that they are identical or increasing in this order. If this is not the case, the timestamps are set to the found minimum.

    CreateDate ≤ DateTimeOriginal ≤ ModifyDate ≤ FileModifyDate ≤ FileInodeChangeDate ≤ FileAccessDate

If a GPS timestamp exists, it is trusted and the CreateDate and DateTimeOriginal values for minutes and seconds are set to those of the GPS timestamp if they were not already identical.

    photo-fix-times.bash [DIRNAME]


### photo-restore-original

This automates the maintenance of the "_original" files created by exiftool. It has no effect on files without an "_original" copy. This restores the files from their original copies by renaming the "_original" files to replace the edited versions in a directory and all its subdirectories.

    photo-restore-original.bash DIRECORY

### photo-set-gps

This extracts GPS geo-location information from files in the given directory and subfolders and stores it in an GPX file, unless it is already available in the same folder.

In a second step it sets(!) the GPS geo-location information for the other files in the given directory and subfolders. Be aware that it will locate the new positions on a straight line between known track-points.

    photo-set-gps.bash DIRNAME

### photo-set-times

This sets the date and time stamps to the given date for one picture file or for all picture files in the given directory (not recursive).

Following timestamps are modified if they existed before:

* CreateDate
* DateTimeOriginal
* SonyDateTime
* ModifyDate
* FileModifyDate


    photo-set-times.bash YYYY:MM:DD hh:mm:ss FILENAME
    photo-set-times.bash YYYY:MM:DD hh:mm:ss [DIRNAME]


### photo-shift-times

This shifts the date and time stamps by the given number of seconds for one picture file or for all pictures in the given directory (not recursive).

Following tmestamps are modified if they existed before:

* CreateDate
* DateTimeOriginal
* SonyDateTime
* ModifyDate
* FileModifyDate


    photo-shift-times.bash SECONDS [FILENAME|DIRNAME]

It is recommended to then move and rename the modified files using `photo-sort-time`.


### photo-sort-time-frame

This moves files from present directory and subfolders to `~/Pictures/sorted/YYYY/YYYY-MM-DD/`.

Images and RAW images are renamed to `YYYYMMDD-hhmmss_ffff.xxx`, based on their CreateDate and Frame Number. Frame Numbers usually only exist where an analogue series of photos was digitalised. If two pictures still end up in the same file-name, it will then be suffixed with a an incremental number: `YYYYMMDD-hhmmss_ffff_n.xxx`.

    photo-sort-time-frame.bash [INDIR [OUTDIR]]

### photo-sort-time-model

This moves files from present directory and subfolders to `~/Pictures/sorted/YYYY/YYYY-MM-DD/`.

Images and RAW images are renamed `YYYYMMDD-hhmmss-model.xxx`, based on their CreateDate and Camera Model Name. If two pictures were taken at the same second by the same camera, the filename will be suffixed with a an incremental number: `YYYYMMDD-hhmmss-model_n.xxx`.

    photo-sort-time-model.bash [INDIR [OUTDIR]]

### photo-sort-time

This moves files from `~/Pictures/INBOX/` and subfolders to `~/Pictures/sorted/YYYY/YYYY-MM-DD/`

Images and RAW images are renamed to `YYYYMMDD-hhmmss.xxx`, based on their CreateDate. If two pictures were taken at the same second, the filename will be suffixed with a an incremental number: `YYYYMMDD-hhmmss_n.xxx`.

    photo-sort-time.bash [INDIR [OUTDIR]]

### merge-gpx

Brain-dead merge of GPX files. Removing all headers and trailers. Output goes to stdout.

    merge-gpx.bash FILE1 FILE2 ...


<!-- 

### photo-check-times.bash

identify photos with illogical time stamps


###	photo-correct-times.bash

create a list of commands to correct date and time stamps


### photo-explain-times.bash

explain output of photo-check-times.bash


### photo-extract-gps.bash

This extracts GPS geo-location information from files in the given directory and subfolders. The data is written in GPX format to stdout.

### photo-restore-original.bash

restore from `_original` files as by ExifTool


### photo-set-times.bash

set date and time to a fixed date


### photo-shift-times.bash

shift date and time by a fixed number of seconds


### photo-sort-time-model.bash

recursively rename and sort photos by creation date and camera model

### photo-sort-time.bash

recursively rename and sort photos by creation date
 -->


## configuration

The directories and other parameters can be configured using configuration files. All found configuration files will be read and values set in earlier files are 
overwritten by values found in later files; in this order:

1) _script dir_/.antu-photo.cfg
2) _script dir_/antu-photo.cfg
3) _user's home dir_/.antu-photo.cfg
3) _user's home dir_/antu-photo.cfg
5) _present dir_/.antu-photo.cfg
6) _present dir_/antu-photo.cfg

If no config file was found, the scripts use a built-in default.

### GPX format

Am example ExifTool print format file `gpx.fmt`for generating GPX track log that also includes a track-name and track-number based on the start time is provided. All input files must contain GPSLatitude and GPSLongitude.

## tested on

| OS            | awk       | bash      | perl   | ExifTool |
|---------------|-----------|-----------|--------|----------|
| macOS 10.12.4 | GNU 4.1.1 | 3.2.57(1) | 5.18.2 | 10.48    |
