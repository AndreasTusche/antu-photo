# AnTu Photo Workflow

I'm an amateur photographer and I take photos at family events or during my holidays, they are my memories and must not be lost. I want the original images to be archived and never be touched again. This is the main requirement for my workflow.

Additionally I'd like to have all images available in a quickly browse-able catalogue. Third party applications may help to add or to search for meta-information.

Most of my photos require retouching or editing. They may or may not replace files which are already in the archive or in the catalogue. Respective working files should be archived aside to the final results.

Problems may occur when I later (re-)discover files that are almost identical to those already in the archive. I need to have an easy way to determine which one is the original or the better version. What happens to the archive and the catalogue when I replace the one with the other?



## Requirements

The workflow is modelled mainly to support these two main requirements:
* Archiving - Put the files in a safe place and never touch again.
* Browsing  - Have all images in a catalogue with metadata.

'Editing' is not part of the workflow because the working files and results are again just a different kind of input to the workflow.



## The workflow

1) [Take photos](#take-photos) - in RAW, JPG or both.
2) [Copy photos to computer](#copy-photos-to-computer) to local Inbox directory 
3) [Pre-Sort photos](#pre-sort-photos)
4) [Review images](#review-images) and trash unwanted
5) Archive best originals, e.g. RAW if available
6) Convert best originals into format for the catalogue
7) Ingest in catalogue
8) Convert best originals into format for editing
9) Archive edited files including sidecar files


``` viz {filename="workflow.png"}
digraph workflow {
    graph [fontsize="8" layout="dot"];
    // node  [shape="box"]
    edge  [fontsize="10"]

    /* locations */
    {node [color=Gold shape=record style=filled fillcolor=Lemonchiffon];
        OldArchive [label="<1> Old Archive\nor Catalogue | { <R> RAW | <J> JPG | <M> MOV | <X> misc}"]
  Inbox      [label="{<1> Inbox | { <R> RAW | <J> JPG | <M> MOV | <X> misc } }"]
        Trash      [label=".Trash"]
        Video      [label="Video Clips\nand Movies"]
        Working    [label="Working Folder"]
        Sorted     [label="<1> Local Archive | <R> RAW | <J> JPG"]
        Catalogue  [label="<1> Catalogue | <J> JPG"]
        NASInbox   [label="<1> NAS Inbox | { <R> RAW | <J> JPG }"]
        Archive    [label="{{ <D> DNG | <O> ORIGINAL | <E> EDITED | <S> SideCar } | <1> Final Archive on NAS}"]
    }


    /* Actions */
    {node [color=Red style=filled fillcolor=moccasin];
        Check      [label="Check\nCamera Settings"]
        Take       [label="Take Photos\nRAW, JPG"]
        Metadata   [label="Correct\nMetadata"]
        Timestamps [label="Correct\nTimestamps"]
        Presort    [label="Presort Images"]
        Review     [label="Review\nand Trash"]
        Shrink      [label="Resize"]
        Identify   [label="Identify original\n or edited"]
        Edit       [label="Edit Images"]
        Publish    [label="Publish"]
    }
    
    /* Scripts */
    {node [color=red shape=box style=filled fillcolor=gold];
        import     [label="photo-import-sd.bash"]
        fixtimes   [label="photo-fix-times.bash"]
        sortphotos [label="antu-sortphotos.bash"]
        nassort   [label="photo-nas-sort.bash"]
    }


    subgraph cluster_cam {
        style="dotted"
        //OldArchive
        Check
        Take
    }

    subgraph cluster_local {
        import
        Inbox
        Metadata
        Timestamps 
        Presort 
//        subgraph cluster_app {
//            style="dotted"
            fixtimes
            sortphotos
//        }
        Review
        Sorted
        Shrink
        Catalogue
        Working
        Edit
    }

    subgraph cluster_nas {
        style="dotted"
        NASInbox
        Identify nassort
        Archive
    }

/* external */
    // Trash

    /* from actions */

    Check          -> Take             [color=gray]
    Edit           -> Working          [color=blue]
    Edit           -> Publish          [color=blue]
    nassort        -> Archive:O        [color=orangered]
    nassort        -> Archive:E        [color=blue]
    Metadata       -> Timestamps
    Presort        -> sortphotos -> Review
    Review         -> Sorted:J         [color=blue]
    Review         -> Sorted:R         [color=orangered]
    Sorted:1:s     -> Working
    Review         -> Trash
    Take           -> import -> Inbox:1:n
    Timestamps     -> fixtimes -> Inbox:1:w

    /* from locations */
    Inbox:J:s      -> Metadata         [color=blue]
    Inbox:R:s      -> Metadata         [color=orangered]
    Inbox:J        -> Presort          [color=blue]
    Inbox:R        -> Presort          [color=orangered]
    Inbox:M        -> sortphotos -> Video
    Inbox:X        -> sortphotos ->  Trash
    NASInbox       -> Identify -> nassort
    OldArchive:1   -> Inbox:1:n
    Sorted:J       -> Shrink           [color=blue]
    Shrink         -> Catalogue:J      [color=blue]
    Sorted:J:s     -> NASInbox         [color=blue]
    Sorted:R:s     -> NASInbox         [color=orangered]
    Working        -> Edit
    Working        -> Inbox:J:se       [color=blue]
}
```



### Take photos

My current camera stores photos as RAW or JPG or both. Usually I want to store as much of the original information as possible and hence I use uncompressed RAW in the highest resolution. Unfortunately, the RAW format is proprietary, which is true for almost all cameras, and my computer cannot quickly display the image in the Finder - it just takes ages. Hence, for browsing purposes, I set the camera to also store the JPG directly on the SD card.

My camera also allows for some special scenes, like panorama or multi-exposure. Those photos are not stored as RAW but only as JPG. My older cameras used different RAW formats or did not support RAW at all. In both cases those non-RAW files are still the best available originals and have to be handled as such. This has to be taken account for in the further workflow.

Most cameras add meta-information, like time-stamps, exposure and lens settings. Ideally that goes to the EXIF header of the image files. Sometimes extra information comes from other sources, e.g. an GPS tracker for geo-location. In my case, I try to take at least one photo with my smart phone at every new location. Usually those phone photos get thrown away after I extracted the geo-location. Be prepared that some of the meta-information may not be very accurate though.

To allow later chronological sorting, time-stamps should at least be accurate by the day. When shooting with two or more cameras simultaneously, you want to have the time accurate to the second. So, always check the camera time before shooting; additionally take a photo of a very accurate time display, e.g. [https://time.is](). When you are in the wild, try to take one shot with all cameras simultaneously. Both options allow for later precise corrections.

Older photos may origin from Photo CDs, scans of paper photos or of film negatives. The meta-information of those files usually does not exist or is of little or no use. Be prepared for manual work.

| In brief |
|:-|
| Use RAW whenever possible. |
| At each location use a GPS tracker or take one photo with a geo-location phone. |
| Always have the camera clock precisely set and take a photo of an accurate time-stamp. |


### Copy Photos to Computer

Before sorting the photos I had to make my mind up where to sort them to. A directory structure in the file system has to be created. I just want them sorted by date and time but then there are the original files, edited files, maybe the catalogue and perhaps some more. This requires a more sophisticated structure.

#### Directory structure

This is the directory structure which I decided to use. It may look somewhat overdone, I’ll explain it in the following.

```
    ~
    ├── .Trash
	├── Movies
	│   └── REVIEW
	│   │   └── YYYY
	│   │       └── YYYY-MM-DD
    │   └── YYYY
    │       └── YYYY-MM-DD
    └── Pictures
        ├── CATALOGUE
        │   └── YYYY
        │       └── YYYY-MM-DD
        ├── EDIT
        |   ├── SideCar
        │   |   └── YYYY
        │   |       └── YYYY-MM-DD
        │   └── YYYY
        │       └── YYYY-MM-DD
        ├── INBOX
        ├── ORIGINAL
        │   └── YYYY
        │       └── YYYY-MM-DD
        ├── published
        │   └── [where]
        │       └── YYYY
        │           └── YYYY-MM-DD
        └── REVIEW
	        ├── ERROR
	        │   └── DUPLICATES
	        ├── TMP
	        ├── RAW
	        └── YYYY
	            └── YYYY-MM-DD
```

##### Subdirectories and file names

I just want my photos sorted by date and time, I do not want to have additional sorting options, e.g. by camera, lens, events, locations or people. Anyhow I discuss some options that you may consider for your workflow.

###### By Date and Time

The final location has a directory per year and subdirectories per day. Files are renamed to the date and time, like this

    ./YYYY/YYYY-MM-DD/YYYYMMDD-hhmmss.jpg

###### By Date, Time and Frame

If several pictures were shot at the same second, then a two-digit frame number may be added, like this

    ./YYYY/YYYY-MM-DD/YYYYMMDD-hhmmss_ff.jpg

This allows for up to 100 photos per second, about four times the frame rate of a conventional movie. This is my default setting and confogured as such in the [antu-photo.cfg]() configuration file.

###### By Start, End, and Production Date and Time

For single shots the creation date is enough but when you are also taking very long exposures or video clips you may want to have a start and end date. Maybe you also want a modification date in the filename, like so

```
     ./YYYY/YYYY-MM-DD/YYYYMMDDhhmmss_YYYYMMDDhhmmss_YYYYMMDDhhmmss.jpg
                       |              |              |
start date and time ---+              |              |
  end date and time ------------------+              |
 edit date and time ---------------------------------+
```

Try not to become too creative here, the simpler, the easier it is to maintain in future.

###### By Date, Time and Model

Combining photos from shootings with your mates becomes tricky if not everybody had the same accurate time settings on their cameras. Sorting the photos by camera model may then aid to correct them individually, like this

    ./YYYY/YYYY-MM-DD/YYYYMMDD-hhmmss-model.jpg

The little script [photo-sort-time-model.bash](#photo-sort-time-model) may help here.

##### Inbox

Wherever the photos are coming from - the SD card of the camera, an USB stick, other directories - the automated workflow should always start at the very same place. This allows full control on which files are processed and minimises fatal errors by accidentally using a wrong source directory.

I copy _all_ photos I took from the camera SD card to the Inbox:

    ~/Pictures/INBOX/

Doing this step manually usually avoids creating duplicates. The original files stay on the SD card until I have at least properly archived these new files. If I accidentally corrupt the new files on my computer, if one of my scripts develops its own mind or if something else goes wrong, then I always can start over, going back to the originals from the SD card.

Copying can be done using the Finder or, as I prefer it, from the Unix command line, using `rsync`. In case of partial transfers the incomplete files should be kept away in a dedicated directory. So I type

``` shell
cd /Volumes/SD_Card/DCIM
rsync -rtv --partial-dir=~/Pictures/REVIEW/ERROR . ~/Pictures/INBOX/
```

Scripting this step is not straight forward as every SD card is going to be mounted under a new name; nevertheless I gave it a try and wrote the script [photo-import-sd.bash](#photo-import-sd) for Mac OS X.

### Pre-sort photos

#### Stage 1

I could start checking the photos already now and throw away failed ones - but I don't. In the Inbox I may have a mix of RAW, JPG files and eventually some video clips or any other stuff that I don't need. 

All files need to be sorted in respective directories for a first manual inspection. In this order

Unwanted stuff goes to
: `~/Pictures/REVIEW/ERROR/`

Video clips go to
: `~/Movies/REVIEW/YYYY/YYYY-MM-DD/`

RAW images go to
: `~/Pictures/ORIGINAL/YYYY/YYYY-MM-DD/`

Edited images go to
: `~/Pictures/EDIT/YYYY/YYYY-MM-DD/`

Sidecar files go to
: `~/Pictures/EDIT/SideCar/YYYY/YYYY-MM-DD/`

Regular photos get sorted to
: `~/Pictures/REVIEW/YYYY/YYYY-MM-DD`

Duplicates go to
: `~/Pictures/REVIEW/ERROR/DUPLICATES/`

Unwanted stuff are image-catalogues, application directories or third party libraries that may be mistaken as images in a later step. They are recognised by their file extension:

    .app .dmg .icbu .imovielibrary .keynote .oo3 .mpkg .numbers
    .pages .photoslibrary .pkg .theater .webarchive
	
In above list, the `.imovielibrary` and `.photoslibrary` actually are directories created by the macOS iMovie or Photo Applications respectively. They are problematic because they not only contain the original videos or photos but also a lot of smaller, cropped or edited variants or thumbnails. If you want to extract the originals from there, then just place the `.imovielibrary/*/Original Media/` or `.photoslibrary/Masters/` directories in the INBOX (`~/Pictures/INBOX/`).

Movies are recognised by their file extension:

    .3g2 .3gp .asf .avi .drc .flv .f4v .f4p .f4a .f4b .lrv .m4v
    .mkv .mov .qt .mp4 .m4p .moi .mod .mpg .mp2 .mpeg .mpe .mpv
    .mpg .mpeg .m2v .ogv .ogg .pgi .rm .rmvb .roq .svi .vob
    .webm .wmv .yuv

RAW images are recognised by their file extension:

    .3fr .3pr .ari .arw .bay .cap .ce[12] .cib .cmt .cr[23] .craw
    .crw .dc2 .dcr .dcs .dng .eip .erf .exf .fff .fpx .gray
    .grey .gry .iiq .kc2 .kdc .kqp .lfr .mdc .mef .mfw .mos .mrw
    .ndd .nef .nop .nrw .nwb .olr .orf .pcd .pef .ptx .r3d .ra2
    .raf .raw .rw2 .rwl .rwz .sd[01] .sr2 .srf .srw .st[45678]
    .stx .x3f .ycbcra

Edited images are recognised by their file extension:

    .afphoto .bmp .eps .pdf .psd .tif .tiff

Sidecar files are holding additional information like geo-location or about image manipulation steps and are created by many 3^rd^ party applications. They are recognised by their file extension:

    .cos .dop .gpx .nks .pp3 .ppx .prb .?s.spd

For each of the above categories the files are first moved to a temporary working directory `~/Pictures/REVIEW/tmp_sortphotos/`. For example

``` shell
EXT="afphoto|bmp|eps|pdf|psd|tif|tiff"
DIR="~/Pictures/REVIEW/TMP/"

find -E . -iregex ".*\.($EXT)" -exec mv -v -n "{}" "$DIR" \;
```

From there the images, RAW images or files are renamed to `YYYYMMDD-hhmmss.xxx`. If two or more files were taken at the same second, the filename will be suffixed with a an incremental frame number: `YYYYMMDD-hhmmss_ff.xxx`. The renamed files are moved to the respective `YYYY/YYYY-MM-DD` directories. 

At any time, duplicated files may be identified. Binary identical files will be moved to the Trash, leaving only one copy. Other files which seem to be identical in any other way are moved to `~/Pictures/REVIEW/ERROR/DUPLICATES/` for later manual inspection.

For my workflow, the duplicates are the biggest problem — I shall write an extra chapter for this. 


#### Automate it - the script

##### The ExifTool

All the heavy-lifting is done by the excellent [ExifTool](http://www.sno.phy.queensu.ca/~phil/exiftool/) by Phil Harvey.

The ExifTool is a platform-independent Perl library plus a command-line application for reading, writing and editing meta information in a wide variety of files. ExifTool supports many different metadata formats.

The MacOS package installs the ExifTool command-line application and libraries in `/usr/local/bin`. When installing via [Homebrew](http://brew.sh/) the files are installed at `/usr/local/Cellar/exiftool/[version]/bin/exiftool` and then linked to `/usr/local/bin`.

After installing, type `exiftool` in a Terminal window to run exiftool and read the application documentation. It has a steep learning curve but is worth it.

A Note to Unix Power-Users. If you find the need to use "find" or "awk" in conjunction with ExifTool, then you probably haven't discovered the full power of ExifTool. Read about the `-ext`, `-if`, `-p` and `-tagsFromFile` options in the application documentation. (This is common mistake number 3.) Often users write shell scripts to do some specific batch processing when the exiftool application already has the ability to do this either without scripting or with a greatly simplified script. This includes the ability to recursively scan sub-directories for a specific file extension (case insensitive), rename files from metadata values, and move files to different directories.

Nevertheless, I wrote some scripts — mainly to store those powerful one-liners.

##### Sorting by date and time

The ExifTool can check for available timestamps within the image files. If a `CreateDate` was found, that one is used, else use `DateTimeOriginal`, `ModifyDate` or `FileModifyDate` in that order. All files are renamed and sorted into the directory structure, subdirectories are created as needed.

``` shell
exiftool -m -r \
    -d "~/Pictures/REVIEW/%Y/%Y-%m-%d/%Y%m%d-%H%M%S%%+.2nc.%%le"\
    "-FileName<FileModifyDate"\
    "-FileName<ModifyDate"\
    "-FileName<DateTimeOriginal"\
    "-FileName<CreateDate"\
    "~/Pictures/REVIEW/TMP/"
```

The above file-naming works well if there wasn’t more than one photo taken per second. If several photos were taken in a series, then the EXIF data may contain a frame number which can be used to distinguish between them. The command would then read:

``` shell
exiftool -m -r \
    -if '$FrameNumber'  \
    -d "~/Pictures/REVIEW/%Y/%Y-%m-%d/%Y%m%d-%H%M%S"\
    '-FileName<${FileModifyDate}_${FrameNumber}%+.2nc.${FileTypeExtension}'\
    '-FileName<${ModifyDate}_${FrameNumber}%+.2nc.${FileTypeExtension}'\
    '-FileName<${DateTimeOriginal}_${FrameNumber}%+.2nc.${FileTypeExtension}'\
    '-FileName<${CreateDate}_${FrameNumber}%+.2nc.${FileTypeExtension}'\
    "~/Pictures/REVIEW/TMP/"
```

Unfortunately live isn’t always that straight forward. Some manufactures use a sequence number, others use a frame number. Additionally the `FileModifyDate` does not always work well with the other time-stamps. The final [`photo-sort-time-frame.bash`][#photo-sort-time-frame] script needed to be somewhat more sophisticated.

###### Correcting timestamps

As mentioned earlier, the meta-data may not be as accurate as wanted. Especially for older photos, which may have been touched by some 3^rd^ party software, the time-stamps may be wrong. As a rule of thumb it can be assumed that the oldest time-stamp is the actual creation date. If a GPS timestamp exists, it is preferable to trust that one.

In some cases the timestamp is not valid at all. I found that the iPhone 5S delivers illegal date values like `GPSDateTime: 2015:08:233 23:15:05.72Z`, where the date (`233`) is the day-of-year.

The following command can be used to extract most common time-stamps and present them as a csv list per file.

``` shell
exiftool \
    -csv -d "%s" -f -m -progress: -q -r \
    -GPSDateTime -CreateDate -DateTimeOriginal -ModifyDate -FileModifyDate -FileInodeChangeDate -FileAccessDate \
    "~/Pictures/REVIEW/TMP/"
```

Once the minimum timestamp is identified for each file, all other timestamps can be adjusted, if needed. Provide the timestamp as a variable `mindate` in the format `"%Y:%m:%d %H:%M:%S"` and then use the ExifTool again for each file:

``` shell
exiftool \
    -m -overwrite_original_in_place -q \
    -AllDates="$mindate" -IFD1:ModifyDate="$mindate" -FileModifyDate="$mindate" \
    "~/Pictures/REVIEW/TMP/<<<MyFile>>>"
```

> I did not yet find an option to extract time-stamps and set them to the minimum in _one single_ ExifTool call. I'd be interested to hear back from you.

Obviously time stamps should be correct before files are renamed and sorted. The script [antu-sortphotos.bash](#antu-sortphotos) first calls the small helper script [photo-fix-times.bash](#photo-fix-times) which also takes care of the iPhone bug and then it calls [photo-sort-time-frame.bash](#photo-sort-time-frame) which recursively renames and sorts photos by creation-date and frame-number.

| In brief |
|:-|
| Create a directory structure that supports your workflow.  |
| Use the ExifTool to extract, correct time-spans or to modify meta-information. |
| Use the ExifTool to sort files in places for review. |


### Review images

This step is completely manual. Some photos just belong in the Trash.

Well, I check JPG files only and move them to the Trash if they deserve it, but I want to get rid of the respective RAW as well. The little script [photo-trash.bash](#photo-trash) moves corresponding RAW files to the Trash, they are easily identified by the same file-base-name, i.e. the time-stamp.


| In brief |
|:-|
| Review files and trash bad photos.  |


### Archive best originals, e.g. RAW if available
_tbw_

### Convert best originals into format for the catalogue
_tbw_

### Ingest in catalogue
_tbw_

### Convert best originals into format for editing
_tbw_

### Archive edited files including sidecar files -  but apart from originals
_tbw_



## The Scripts explained

~~I also do not want to rename files manually.~~

All these scripts were written for MAC OS X. That operating system provides Unix tools which may not be available on any other Unix distribution. If you port the scripts to any other machine, I'd like to hear back from you.

| OS            | awk       | bash      | perl   | ExifTool |
|---------------|-----------|-----------|--------|----------|
| macOS 10.12.4 | GNU 4.1.1 | 3.2.57(1) | 5.18.2 | 10.48    |
| macOS 10.13.6 | GNU 4.2.0 | 3.2.57(1) | 5.18.2 | 11.23    |



### antu-sortphotos

This script moves files in this order
  * movies to        `~/Movies/YYYY/YYYY-MM-DD/`
  * raw images to    `~/Pictures/RAW/YYYY/YYYY-MM-DD/`
  * edited images to `~/Pictures/edit/YYYY/YYYY-MM-DD/`
  * photos to        `~/Pictures/REVIEW/YYYY/YYYY-MM-DD/`

Filetypes are recognised by their file extensions.
Images and RAW images are renamed to `YYYYMMDD-hhmmss.xxx`, duplicates are not kept but if two files were taken at the same second, the filename will be suffixed with a an incremental number: `YYYYMMDD-hhmmss_n.xxx`.

```shell
#!/bin/bash
DIR_ANTU_PHOTO="${0%/*}"
CMD_correcttim="${DIR_ANTU_PHOTO}/photo-fix-times.bash"
CMD_sortphotos="${DIR_ANTU_PHOTO}/photo-sort-time-frame.bash"

DIR_EDT=~/Pictures/edit/
DIR_ERR=~/Pictures/ERROR/
DIR_MOV=~/Movies/
DIR_PIC=~/Pictures/REVIEW/
DIR_RAW=~/Pictures/RAW/
DIR_SRC=~/Pictures/INBOX/
DIR_TMP=~/Pictures/REVIEW/tmp_sortphotos/

RGX_EDT="afphoto|bmp|eps|ico|pdf|psd"
RGX_BAD="app|dmg|icbu|imovielibrary|keynote|oo3|mpkg|numbers|pages|potoslibrary|pkg|theater|webarchive"
RGX_MOV="3g2|3gp|aae|asf|avi|drc|flv|f4v|f4p|f4a|f4b|lrv|m4v|mkv|modmoi|mov|qt|mp4|m4p|mpg|mp2|mpeg|mpe|mpv|mpg|mpeg|m2v|ogv|ogg|pgi|rm|mvb|roq|svi|vob|webm|wmv|yuv"
RGX_RAW="3fr|3pr|ari|arw|bay|cap|ce[12]|cib|cmt|cr[23]|craw|crw|dc2|dcr|dcs|dng|eip|erf|exf|fff|fpx|gray|grey|gry|heic|iiq|kc2|kdc|kqp|lfr|mdc|mef|mfw|mos|mrw|ndd|nef|nop|nrw|nwb|olr|orf|pcd|pef|ptx|r3d|ra2|raf|raw|rw2|rwl|rwz|sd[01]|sr2|srf|srw|st[45678]|stx|x3f|ycbcra"

cd $DIR_SRC
# move errornous files out of the way
find -E . -iregex ".*\.($RGX_BAD)" -exec mv -v -n "{}" $DIR_ERR \;

# move and rename Videos
find -E . -iregex ".*\.($RGX_MOV)" -exec mv -v -n "{}" $DIR_TMP \;
$CMD_correcttim $DIR_TMP
$CMD_sortphotos $DIR_TMP $DIR_MOV

# move and rename RAW files
find -E . -iregex ".*\.($RGX_RAW)" -exec mv -v -n "{}" $DIR_TMP \;
$CMD_correcttim $DIR_TMP
$CMD_sortphotos $DIR_TMP $DIR_RAW

# move and rename edited files
find -E . -iregex ".*\.($RGX_EDT)" -exec mv -v -n "{}" $DIR_TMP \;
$CMD_correcttim $DIR_TMP
$CMD_sortphotos $DIR_TMP $DIR_EDT

# move and rename all remaining picture files
$CMD_correcttim $DIR_SRC
$CMD_sortphotos $DIR_SRC $DIR_PIC
```
The complete script: [antu-sortphotos.bash]()



### The scripts



#### photo-extract-gps

This extracts GPS geo-location information from files in the given directory and subfolders and writes the result in GPX format to stdout.

```sh
photo-extract-gps.bash DIRNAME
```



#### photo-fix-times

Uses ExifTool to identify the following timestamps. It is expected that they are identical or increasing in this order. If this is not the case, the timestamps are set to the found minimum.

```shell
CreateDate
    ≤ DateTimeOriginal
    ≤ ModifyDate
    ≤ FileModifyDate
    ≤ FileInodeChangeDate
    ≤ FileAccessDate
```

If a GPS timestamp exists, it is trusted and the CreateDate and DateTimeOriginal values for minutes and seconds are set to those of the GPS timestamp if they were not already identical.

    photo-fix-times.bash [DIRNAME]

**Note:** This script uses GNU awk (`gawk`) which can be installed using Homebrew, e.g.

    brew install gawk


#### photo-import-sd

The mount point of SD Cards is different for each card. This scripts tries to find it and then copies all Photos from the `DCIM` to the Inbox directory. By the way, it does not keep track of past copy activities and hence this script may produce a lot of duplicate files on your disk, if you don't take care.

```shell
#!/bin/bash

DIR_DCF=''                             # mount point of SD Card
DIR_PIC=~/Pictures/                    # Local Pictures directory
DIR_SRC=${DIR_PIC%/}/INBOX/            # start point, files are moved from here to their destinations
DIR_ERR=${DIR_PIC%/}/ERROR/            # something went wrong, investigate

# find SD Card and its mount point (i.e its path)
if [[ "$DIR_DCF" == "" ]]; then
	# get all mounted disks
	list=$( diskutil list | awk '/0:/{printf $NF" "}')
	
	# search for SD Card Reader
	for i in $list; do
		diskutil info $i | grep "SD Card Reader" >/dev/null
		if [[ "$?" == "0" ]]; then
			sdCard=$i
			break
		fi
	done
	
	if [[ "$sdCard" == "" ]]; then
		echo "No SD Card found"
		exit 1
	fi
	
	# get mount point of SD Card
	DIR_DCF=$( diskutil info ${sdCard}s1 | awk -F: '/Mount Point/{gsub(/^[ \t]+/, "", $2); print $2}' )
fi

# copy photos
cd $DIR_DCF/DCIM
rsync -rtv --partial-dir=$DIR_ERR . $DIR_SRC

```
The complete script: [photo-import-sd.bash]()


#### photo-restore-original

This automates the maintenance of the "\_original" files created by exiftool. It has no effect on files without an "\_original" copy. This restores the files from their original copies by renaming the "\_original" files to replace the edited versions in a directory and all its subdirectories.

    photo-restore-original.bash DIRECORY

#### photo-set-gps

This extracts GPS geo-location information from files in the given directory and subfolders and stores it in an GPX file, unless it is already available in the same folder.

In a second step it sets(!) the GPS geo-location information for the other files in the given directory and subfolders. Be aware that it will locate the new positions on a straight line between known track-points.

    photo-set-gps.bash DIRNAME

#### photo-set-times

This sets the date and time stamps to the given date for one picture file or for all picture files in the given directory (not recursive).

Following timestamps are modified if they existed before:

* CreateDate
* DateTimeOriginal
* SonyDateTime
* SonyDateTime2
* ModifyDate
* FileModifyDate


    photo-set-times.bash YYYY:MM:DD hh:mm:ss FILENAME
    photo-set-times.bash YYYY:MM:DD hh:mm:ss [DIRNAME]


#### photo-shift-times

This shifts the date and time stamps by the given number of seconds for one picture file or for all pictures in the given directory (not recursive).

Following tmestamps are modified if they existed before:

* CreateDate
* DateTimeOriginal
* SonyDateTime
* SonyDateTime2
* ModifyDate
* FileModifyDate


    photo-shift-times.bash SECONDS [FILENAME|DIRNAME]

It is recommended to then move and rename the modified files using `photo-sort-time`.


#### photo-sort-time-frame

This moves files from present directory and subfolders to `~/Pictures/REVIEW/YYYY/YYYY-MM-DD/`.

Images and RAW images are renamed to `YYYYMMDD-hhmmss_ffff.xxx`, based on their CreateDate and Frame Number. Frame Numbers usually only exist where an analogue series of photos was digitalised. If two pictures still end up in the same file-name, it will then be suffixed with a an incremental number: `YYYYMMDD-hhmmss_ffff_n.xxx`.

    photo-sort-time-frame.bash [INDIR [OUTDIR]]

#### photo-sort-time-model

This moves files from present directory and subfolders to `~/Pictures/REVIEW/YYYY/YYYY-MM-DD/`.

Images and RAW images are renamed `YYYYMMDD-hhmmss-model.xxx`, based on their CreateDate and Camera Model Name. If two pictures were taken at the same second by the same camera, the filename will be suffixed with a an incremental number: `YYYYMMDD-hhmmss-model_n.xxx`.

    photo-sort-time-model.bash [INDIR [OUTDIR]]

#### photo-sort-time

This moves files from `~/Pictures/INBOX/` and subfolders to `~/Pictures/REVIEW/YYYY/YYYY-MM-DD/`

Images and RAW images are renamed to `YYYYMMDD-hhmmss.xxx`, based on their CreateDate. If two pictures were taken at the same second, the filename will be suffixed with a an incremental number: `YYYYMMDD-hhmmss_n.xxx`.

    photo-sort-time.bash [INDIR [OUTDIR]]

#### photo-sort-time-frame

Like above [photo-sort-time.bash][#photo-sort-time] script.

#### photo-trash

A brain-dead script to find corresponding RAW files to already trashed JPG files and vice versa.

```shell
#!/bin/bash

DIR_RAW=~/Pictures/ORIGINAL/
RGX_DAT="[12][09][0-9][0-9][01][0-9][0-3][0-9]-[012][0-9][0-5][0-9][0-6][0-9]"

cd ~/.Trash
for f in ${RGX_DAT}.jpg ${RGX_DAT}_[1-9].jpg; do
mv $DIR_RAW/${f:0:4}/${f:0:4}-${f:4:2}-${f:6:2}/${f%.*}.* .
done
```

The complete script also checks Trashes of external drives or USB sticks: [photo-trash.bash]()

#### merge-gpx

Brain-dead merge of GPX files. Removing all headers and trailers. Output goes to stdout.

    merge-gpx.bash FILE1 FILE2 ...




#### photo-check-times.bash

identify photos with illogical time stamps


#### photo-correct-times.bash

create a list of commands to correct date and time stamps


#### photo-explain-times.bash

explain output of photo-check-times.bash


#### photo-extract-gps.bash

This extracts GPS geo-location information from files in the given directory and subfolders. The data is written in GPX format to stdout.

#### photo-restore-original.bash

restore from `_original` files as by ExifTool


#### photo-set-times.bash

set date and time to a fixed date


#### photo-shift-times.bash

shift date and time by a fixed number of seconds


#### photo-sort-time-model.bash

recursively rename and sort photos by creation date and camera model

#### photo-sort-time.bash

recursively rename and sort photos by creation date


### configuration

The directories and other parameters can be configured using configuration files. All found configuration files will be read and values set in earlier files are overwritten by values found in later files; in this order:

1) _script dir_/.antu-photo.cfg
2) _script dir_/antu-photo.cfg
3) _user's home dir_/.antu-photo.cfg
4) _user's home dir_/antu-photo.cfg
5) _present dir_/.antu-photo.cfg
6) _present dir_/antu-photo.cfg

If no config file was found, the scripts use built-in default.


### GPX format

Am example ExifTool print format file `gpx.fmt` for generating GPX track log that also includes a track-name and track-number based on the start time is provided. All input files must contain GPSLatitude and GPSLongitude.
