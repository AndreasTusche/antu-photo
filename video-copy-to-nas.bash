#!/bin/bash
#
# move mp4 from current dir to NAS - EDIT version


#!#####################
echo "needs rewrite" #!
exit 1               #!
#!#####################


DIR_EDT=/Volumes/video/EDIT

for video in *.mp4; do
	f=$(basename "$video") 
	[[ "${f%.*}00000000000000" =~ ([0-9]{4}|[0-9]{2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2}).* ]]
	read t Y M D h m s <<< ${BASH_REMATCH[@]//[!0-9]/}
	read Y M D h m s <<< $( date +"%Y %m %d %H %M %S"  -d "$Y-1-1 +$(( 10#$M-1 )) months +$(( 10#$D-1 )) days +$h hours +$m minutes +$s seconds" )

	subdir=${Y}/${Y}-${M}-${D}                # directory under DIR_EDT
	video_out="${Y}${M}${D}-${h}${m}${s}"     # without extension
	
	mkdir -p $DIR_EDT/$subdir
	echo "$f --> $DIR_EDT/$subdir/${video_out}.mp4"
	rsync -t $f $DIR_EDT/$subdir/${video_out}.mp4
done
