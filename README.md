# Magic Music

Magic Music is a prototype for the automatic generation of music soundtracks for videos. It employs the following:

* ffmeg for video analysis
* TensorFlow/Magenta for melody and beat creation
* SuperCollider for audio synthesis

## How it works

1. Accepts a random video as a seed (1-2m videos with several scene changes are ideal, e.g. [GoPro Videos](https://vimeo.com/gopro/videos/page:75/sort:duration/format:thumbnail)
2. Uses ffmpeg to extract onset times of major scene changes
3. Determines a best approximate "beat" of the video based on scene change onset times
4. Performs a kind of [video quantization](https://en.wikipedia.org/wiki/Quantization_(music)) by altering the speed of each scene based on this approximated beat so that the scene's length becomes a multiple of the beat
5. Concatenates the altered segments into a new output video with scene changes at regular beats
6. Uses Tensorflow/Magenta to create melodies and rhythms set to the video's scene change beat
7. Mixes the generated music with the output video

## Dependencies

* TensorFlow
* Magenta
* ffmpeg and ffprobe
* SuperCollider

## Usage

Within the magic_music root directory, execute:

`bash RunMe.sh path_to_your_video.mp4`
