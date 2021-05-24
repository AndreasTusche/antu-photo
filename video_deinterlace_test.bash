#!/bin/bash
#
# ffmpeg includes several deinterlacers:
# 
# bwdif: ‘Bob Weaver Deinterlacing Filter’
# kerndeint: adaptive kernel deinterlacing
# nnedi: uses neural network edge directed interpolation - BEST OPTION USED HERE
# w3fdif: ‘Weston 3 Field Deinterlacing Filter’
# yadif: ‘yet another deinterlacing filter’
#
# Input is DCR Quicktime video:
# Stream #0:0(und): Video: dvvideo (dvcp / 0x70637664), yuv420p(smpte170m/bt470bg/bt709, bottom coded first (swapped)), 720x576 [SAR 16:15 DAR 4:3], <20Mb/s, SAR 59:54 DAR 295:216, 25 fps, 25 tbr, 25k tbn, 25 tbc (default)
# Stream #0:2(und): Audio: pcm_s16le (lpcm / 0x6D63706C), 48000 Hz, stereo, s16, 1536 kb/s (default)

# example for a 2x2 grid for comparision:
# ffmpeg -i top_l.mp4 -i top_r.mp4 -i bottom_l.mp4 -i bottom_r.mp4 -i audio.mp4 -filter_complex "[0:v][1:v]hstack[t];[2:v][3:v]hstack[b];[t][b]vstack[v]" -map "[v]" -map 4:a -c:a copy -shortest output.mp4


#!#####################
echo "needs rewrite" #!
exit 1               #!
#!#####################



DEBUG=1
video="$1"          # input filename
ext="mp4"           # output file extension

# Parsing the filename for date and time. It will be interpreted in the order of 
# "Y M D h m s"
# This is very flexible about the actual format of input date/time values, and
# will attempt to reformat any values into the standard format. Any separators
# may be used (or in fact, none at all). The first 4 consecutive digits found in
# the value are interpreted as the year, then next 2 digits are the month, and
# so on. The year must be 4 digits but 2 digits are allowed if the subsequent
# character is a non-digit, and other fields are expected to be 2 digits, but a
# single digit is allowed if the subsequent character is a non-digit.
# If a field exceeds the maximum allowed number, then the excess will just be
# added, e.g. "1999-02-29 00:64:00" will be normalised to "1999-03-01 01:04:00"

f=$(basename "$video") 
[[ "${f%.*}00000000000000" =~ ([0-9]{4}|[0-9]{2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2})([^0-9]*[0-9]{1,2}).* ]]
read t Y M D h m s <<< ${BASH_REMATCH[@]//[!0-9]/}
read Y M D h m s <<< $( date +"%Y %m %d %H %M %S"  -d "$Y-1-1 +$((M-1)) months +$((D-1)) days +$h hours +$m minutes +$s seconds" )

timestamp="${Y}-${M}-${D}T${h}:${m}:${s}" # in YY-MM-DDThh:mm:ss
video_out="${Y}${M}${D}-${h}${m}${s}"     # without extension



# Audio Codec
audio_codec="aac"

# Audio Filter
# bandreject:
# - Apply a bandstop filter to remove specific camera motor noise
# - 1st central frequency 21632 Hz +- 50 Hz
# - 2nd central frequency 23006 Hz +- 50 Hz
# afftdn:
# - Denoise audio samples with FFT.
# - Set the noise type: vinyl noise.
# - Enable noise tracking, noise floor is automatically adjusted.
# adeclick:
# - Remove impulsive noise from input audio.
#
# Use this to visualize the cleaned-up result
# ffplay -f lavfi "amovie=$video,$audio_filter,asplit=2[out1][a]; [a]showspectrum=color=terrain:legend=1:orientation=vertical:overlap=1:s=2048x1024:scale=cbrt[out0]"

audio_filter="\
bandreject=f=21633:t=h:w=50:m=1,\
bandreject=f=21631:t=h:w=30:m=1,\
bandreject=f=21632:t=h:w=10:m=1,\
bandreject=f=23007:t=h:w=50:m=1,\
bandreject=f=23005:t=h:w=30:m=1,\
bandreject=f=23006:t=h:w=10:m=1,\
afftdn=nt=v:tn=1,\
adeclick\
"



# Video Codec
video_codec="libx264"

# compare up to three deinterlacer
# nnedi:
# - Deinterlace video using neural network edge directed interpolation.
# 	- weights file from https://github.com/dubhater/vapoursynth-nnedi3/blob/master/src/nnedi3_weights.
#   => output is 25 fps, takes 20 times longer than yadif=mode=0 (120s)
# yadif:
# - Deinterlace the input video ("yadif" means "yet another deinterlacing filter").
# 	- mode 0: Output one frame for each frame.
#   => output is 25 fps, (reference time, 6.0s)
#   - mode 1: Output one frame for each field.
#   => output is 50 fps, takes 1.5 times longer than yadif=mode=0 (9.9s)
# bwdif:
# - Motion adaptive deinterlacing based on yadif with the use of w3fdif and cubic interpolation algorithms.
# 	- mode 0: Output one frame for each frame.
#   => output is 25 fps, (reference time, 6.8s)
#   - mode 1: Output one frame for each field.
#   => output is 50 fps, takes 1.5 times longer than yadif=mode=0 (9.7s) but better quality!
# w3fdif:
# 9.906s for w3fdif=filter=simple
# 10.223s for w3fdif=filter=complex 

#video_deinterlace[0]="nnedi=weights=nnedi3_weights.bin:nsize=s32x4:nns=n128:etype=s:qual=slow"
#video_deinterlace[0]="nnedi=weights=nnedi3_weights.bin"
#video_deinterlace[0]="yadif=mode=1"
#video_deinterlace[0]="bwdif=mode=0"
video_deinterlace[1]="bwdif=mode=1"
video_deinterlace[2]="w3fdif=filter=simple"
video_deinterlace[3]="w3fdif=filter=complex"


# Video Filter Pass 1/2
# vidstabdetect:
# - Analyze video stabilization/deshaking. Perform pass 1 of 2

video_filter_1="\
vidstabdetect\
"



# Video Filter Pass 2/2
# fillborders:
# - Fill borders of the input video, which can have garbage at the four edges
# - This one has 2 px at the top and left side with funny colours
# vidstabtransform:
# - Video stabilization/deshaking: pass 2 of 
# - optimal adaptive zoom value is determined (no borders will be visible)
# - cubic interpolation in both directions (slow)
# format:
# - Set the format to yuv420p
# fftdnoiz:
# - Denoise frames using 3D FFT
# - using 1 previous and 1 next frame
# coreimage:
# - Apply macOS CoreImage Filter (https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html)
# - GammaAdjust Adjusts midtone brightness
# - ColorControls Adjusts saturation, brightness, and contrast values.
# - Vibrance Adjusts the saturation of an image while keeping pleasing skin tones.
# - SharpenLuminance Increases image detail by sharpening. It operates on the luminance of the image; the chrominance of the pixels remains unaffected.
# - UnsharpMask Increases the contrast of the edges between pixels of different colors in an image.
# deband:
# - Remove banding artifacts from input video.

video_filter_2="\
fillborders=left=2:top=2:mode=mirror,\
vidstabtransform=optzoom=2:interpol=bicubic,\
fftdnoiz=sigma=3:prev=1:next=1,\
coreimage=filter=\
CIGammaAdjust@inputPower=0.8#\
CIColorControls@inputSaturation=1.2#\
CIVibrance@inputAmount=0.8#\
CISharpenLuminance@default#\
CIUnsharpMask@default,\
deband,\
format=yuv420p\
"



# MAIN

echo "PROCESSING $video"

# SPEEDTEST
(($DEBUG)) && echo "DEBUG: --- SPEEDTEST --- $f ---"
for i in 1 2 3; do
	cmd=(ffmpeg \
		-benchmark \
		-hide_banner \
		-loglevel panic \
		-i "$video" \
		-an
		-c:v $video_codec -vf "${video_deinterlace[$i]}" \
		"${video_out}_$i.$ext")
	(($DEBUG)) && echo "DEBUG: ${cmd[@]}"
	t0=$(date +%s%N)
	"${cmd[@]}"
	t1=$(date +%s%N)
	dt[$i]=$( bc -l <<< "scale=3;($t1 - $t0) / 1000000000" )
	(($DEBUG)) && echo "DEBUG: ${dt[$i]}s for ${video_deinterlace[$i]}"
done

# 
# exit
# 
# for i in 1 2 3; do
# 	# pass 1/2
# 	(($DEBUG)) && echo "DEBUG: --- PASS 1 --- $f ---"
# 	cmd=(ffmpeg \
# 		-hide_banner \
# 		-i "$video" \
# 		-an \
# 		-c:v "$video_codec" -vf "${video_deinterlace[$i]},$video_filter_1" \
# 		-f null \
# 		- )		
# 	(($DEBUG)) && echo "DEBUG: ${cmd[@]}"
# 	"${cmd[@]}"
# 
# 	# pass 2/2
# 	(($DEBUG)) && echo "DEBUG: --- PASS 2 --- $f ---"
# 	cmd=(ffmpeg \
# 		-hide_banner \
# 		-i "$video" \
# 		-map 0:0 -map 0:2 \
# 		-c:a $audio_codec -af "$audio_filter" \
# 		-c:v $video_codec -vf "${video_deinterlace[$i]},$video_filter_2" \
# 		-movflags faststart -movflags use_metadata_tags \
# 		-map_metadata 0 \
# 		-metadata creation_time="$timestamp" \
# 		"${video_out}_$i.$ext")
# 	(($DEBUG)) && echo "DEBUG: ${cmd[@]}"
# 	"${cmd[@]}"
# done

# Results
for i in 1 2 3; do
 	echo "${dt[$i]}s for ${video_deinterlace[$i]}"
done

echo "DONE: $video"
