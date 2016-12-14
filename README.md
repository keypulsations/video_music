# Magic Music

## What it does:

1. takes a random video as a seed [1-2m GoPro videos with several scene changes are ideal]
2. uses ffmpeg to extract onset times of significant scene changes
3. uses onset times to detect an approximate "beat" of the video based on the onset times of its scene changes
4. based on this approximated beat, alters the speed of each scene so that its length is a multiple of the beat
5. after this "video quantization", concatenates the altered segments into a new video with scene changes at regular beats
6. uses Tensorflow/Magenta to create melodies and rhythms set to the video's beat
7. mixes the output music with the quantized video

`bash RunMe.sh videos/path_to_your_video.mp4`
