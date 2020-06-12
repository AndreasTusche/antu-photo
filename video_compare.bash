#!/bin/bash
# compare original video with 1 or 3 other videos.

DEBUG=1
video="$1"          # input filename of original file
ext="mp4"           # output file extension

# Parsing the filename for date and time. Same as in video_deinterlace.bash
f=$(basename "$video") 
[[ "${f%.*}00000000000000" =~ ([0-9]{4}|[0-9]{2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2}).* ]]
read t Y M D h m s <<< ${BASH_REMATCH[@]//[!0-9]/}
read Y M D h m s <<< $( date +"%Y %m %d %H %M %S"  -d "$Y-1-1 +$((M-1)) months +$((D-1)) days +$h hours +$m minutes +$s seconds" )

v0="$video"
v1="${Y}${M}${D}-${h}${m}${s}_1.$ext"
v2="${Y}${M}${D}-${h}${m}${s}_2.$ext"
v3="${Y}${M}${D}-${h}${m}${s}_3.$ext"
vB="${Y}${M}${D}-${h}${m}${s}.$ext"

# Audio Codec
audio_codec="aac"
# Video Codec
video_codec="libx264"
format="yuv420p"

if [[ -e "$v3" ]]; then
	ffplay -f lavfi -i "amovie=${v0}[out1];movie=${v0}[v0];movie=${v1}[v1];[v0][v1]hstack[t];movie=${v2}[v2];movie=${v3}[v3];[v2][v3]hstack[b];[t][b]vstack"
elif [[ -e "$vB" ]]; then
	ffplay -f lavfi -i "amovie=${v0}[out1];movie=${v0}[v0];movie=${vB}[v1];[v0][v1]hstack"
fi	
