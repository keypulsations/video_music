#!/usr/local/bin/bash
root=$(pwd)
videoPath=$1
songPath=$2
songTempo=$3

# DETERMINE ONSET TIMES OF VIDEO SCENE CHANGES
ffmpeg -i ${videoPath} -filter:v "select='gt(scene,0.4)',showinfo"  -f null  - 2> ${root}/video_onset_times/ffouts/ffout.txt
grep showinfo video_onset_times/ffouts/ffout.txt | grep pts_time:[0-9.]* -o | grep '[0-9]*\.[0-9]*' -o  > video_onset_times/onset_times.txt
mapfile -t onsetTimesArray < video_onset_times/onset_times.txt
separator=","
onsetTimesString="$( printf "${separator}%s" "${onsetTimesArray[@]}" )"
onsetTimesString="${onsetTimesString:${#separator}}" # remove leading separator

# CALCULATE BEST APPROXIMATE BEAT IN SUPERCOLLIDER
ruby ${root}/ruby/execute_video_quantizer.rb "${onsetTimesString}" ${root}/${videoPath} ${root}/${songPath} ${songTempo}
