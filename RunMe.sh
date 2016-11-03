#!/usr/local/bin/bash

# 1. accept video file
# 2. gather scene change onset_times into newfile
# 3. pass onset_times file to supercollider as argument
# 4. split those onset times into an array
# 5. use those onset times to approximate best beat using suggestions by Nathan Ho and Dan Zink
# 6. create music around approximated beat, generating melodies with magenta
# 7. play video simultaneously with music

root=$(pwd)
# ffmpeg -i $1 -filter:v "select='gt(scene,0.4)',showinfo"  -f null  - 2> ${root}/video_onset_times/ffouts/ffout.txt
grep showinfo video_onset_times/ffouts/ffout.txt | grep pts_time:[0-9.]* -o | grep '[0-9]*\.[0-9]*' -o  > video_onset_times/onset_times.txt
mapfile -t onsetTimesArray < video_onset_times/onset_times.txt

separator=","
onsetTimesString="$( printf "${separator}%s" "${onsetTimesArray[@]}" )"
onsetTimesString="${onsetTimesString:${#separator}}" # remove leading separator

echo "${onsetTimesString}"

cd /Applications/SuperCollider/SuperCollider.app/Contents/MacOS
exec ./sclang ${root}/magic_music.scd "${onsetTimesString}" ${root}/$1

# to replace original audio with supercollider output
# ffmpeg -i sample_video.mp4 -i sample_video_scene_changes.aiff -map 0:0 -map 1:0  output.mp4

# to optionally mix in audio...
