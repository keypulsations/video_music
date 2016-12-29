#!/usr/local/bin/bash

root=$(pwd)
videoPath=$1
magentaPath=$2
bundlePath=$3

# DETERMINE ONSET TIMES OF VIDEO SCENE CHANGES
ffmpeg -i ${videoPath} -filter:v "select='gt(scene,0.4)',showinfo"  -f null  - 2> ${root}/video_onset_times/ffouts/ffout.txt
grep showinfo video_onset_times/ffouts/ffout.txt | grep pts_time:[0-9.]* -o | grep '[0-9]*\.[0-9]*' -o  > video_onset_times/onset_times.txt
mapfile -t onsetTimesArray < video_onset_times/onset_times.txt
separator=","
onsetTimesString="$( printf "${separator}%s" "${onsetTimesArray[@]}" )"
onsetTimesString="${onsetTimesString:${#separator}}" # remove leading separator

# GENERATE MAGENTA MELODIES
source activate magenta
cd ${magentaPath}
primerMidi=${root}/primer_midi/primer.mid
outputPath=${root}/generated_melodies
bash ${root}/RunMagenta.sh ${magentaPath} ${bundlePath} ${primerMidi} ${outputPath}
generatedMelodies=(${outputPath}/*)

# CALCULATE BEST APPROXIMATE BEAT IN SUPERCOLLIDER
cd /Applications/SuperCollider/SuperCollider.app/Contents/MacOS
exec ./sclang ${root}/supercollider/calculate_beat.scd "${onsetTimesString}" ${root}/${videoPath} ${generatedMelodies[@]: -1} ${generatedMelodies[@]: -2} ${root}
