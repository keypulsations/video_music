#!/usr/local/bin/bash

root=$(pwd)
ffmpeg -i $1 -filter:v "select='gt(scene,0.4)',showinfo"  -f null  - 2> ${root}/video_onset_times/ffouts/ffout.txt
grep showinfo video_onset_times/ffouts/ffout.txt | grep pts_time:[0-9.]* -o | grep '[0-9]*\.[0-9]*' -o  > video_onset_times/onset_times.txt
mapfile -t onsetTimesArray < video_onset_times/onset_times.txt

separator=","
onsetTimesString="$( printf "${separator}%s" "${onsetTimesArray[@]}" )"
onsetTimesString="${onsetTimesString:${#separator}}" # remove leading separator

echo "${onsetTimesString}"

source activate magenta
cd /Users/paulosetinsky/ai/magenta/magenta
outputDir=/Users/paulosetinsky/ai/magenta/magenta/tmp/generated
bash RunMe.sh ${outputDir}

a=(${outputDir}/*)

cd /Applications/SuperCollider/SuperCollider.app/Contents/MacOS
exec ./sclang ${root}/supercollider/magic_music.scd "${onsetTimesString}" ${root}/$1 ${a[@]: -1} ${a[@]: -2}
