#!/bin/bash
#
# move individual original media from imovielibrary to NAS - ORIGNAL version


#!#####################
echo "needs rewrite" #!
exit 1               #!
#!#####################


DIR=/Volumes/video/ORIGINAL

for imovielibrary in ./*.imovielibrary; do

	echo "imovielibrary: $imovielibrary"

	for dir in "$imovielibrary/"*"/Original Media"; do
		echo "dir          : $dir"

		for video in "$dir/"*.*; do
			f=$(basename "$video") 
			[[ "${f%.*}00000000000000" =~ ([0-9]{4}|[0-9]{2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2}).* ]]
			read t Y M D h m s <<< ${BASH_REMATCH[@]//[!0-9]/}
			read Y M D h m s <<< $( date +"%Y %m %d %H %M %S"  -d "$Y-1-1 +$(( 10#$M-1 )) months +$(( 10#$D-1 )) days +$h hours +$m minutes +$s seconds" )

			subdir=${Y}/${Y}-${M}-${D}                # directory under DIR
			video_out="${Y}${M}${D}-${h}${m}${s}.${f##*.}"
			
			mkdir -p $DIR/$subdir
			echo "               $video --> $DIR/$subdir/${video_out}"
			rsync -t "$video" $DIR/$subdir/${video_out}
		done
	done
done
