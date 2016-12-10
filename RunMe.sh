#!/usr/local/bin/bash
root=$(pwd)

# DETERMINE ONSET TIMES OF VIDEO SCENE CHANGES
# ffmpeg -i $1 -filter:v "select='gt(scene,0.4)',showinfo"  -f null  - 2> ${root}/video_onset_times/ffouts/ffout.txt
grep showinfo video_onset_times/ffouts/ffout.txt | grep pts_time:[0-9.]* -o | grep '[0-9]*\.[0-9]*' -o  > video_onset_times/onset_times.txt
mapfile -t onsetTimesArray < video_onset_times/onset_times.txt
separator=","
onsetTimesString="$( printf "${separator}%s" "${onsetTimesArray[@]}" )"
onsetTimesString="${onsetTimesString:${#separator}}" # remove leading separatorZ

# GENERATE MAGENTA MELODIES
source activate magenta
cd /Users/paulosetinsky/ai/magenta/magenta
outputDir=/Users/paulosetinsky/ai/magenta/magenta/tmp/generated
bash RunMe.sh ${outputDir}
genMels=(${outputDir}/*)

# CALCULATE BEST APPROXIMATE BEAT IN SUPERCOLLIDER
cd /Applications/SuperCollider/SuperCollider.app/Contents/MacOS
exec ./sclang ${root}/supercollider/beat_calculate.scd "${onsetTimesString}" ${root}/$1 ${genMels[@]: -1} ${genMels[@]: -2}
