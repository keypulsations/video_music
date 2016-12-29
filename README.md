# Magic Music

Magic Music is a work in progress that aims for the automatic generation of music soundtracks for videos. This code does a couple of things:

* Generates a simple techno soundtrack for a random video
* Alters that video so that its scenes change with the beat of the music

It currently employs the following:

* ffmpeg for video analysis
* TensorFlow/Magenta for melody and beat creation
* SuperCollider for audio synthesis

Currently, the musical variation is provided by TensorFlow/Magenta in the form of differing melodies and rhythms (but leaves much to be desired!)

## How it works

1. Accepts a random video as a seed (1-2m videos with several scene changes are ideal, e.g. [GoPro Videos](https://vimeo.com/gopro/videos/page:75/sort:duration/format:thumbnail))
2. Uses ffmpeg to extract onset times of major scene changes
3. Determines a best approximate "beat" of the video based on scene change onset times
4. Performs a kind of [video quantization](https://en.wikipedia.org/wiki/Quantization_(music)) by altering the speed of each scene based on this approximated beat so that the scene's length becomes a multiple of the beat
5. Concatenates the altered segments into a new output video with scene changes at regular beats
6. Uses Tensorflow/Magenta to create melodies and rhythms set to the video's scene change beat
7. Mixes the generated music with the output video

## Dependencies

* TensorFlow [needs version]
* Magenta [needs version]
* ffmpeg and ffprobe [needs version]
* SuperCollider [needs version]

## Usage

Within the magic_music root directory, execute:

`bash RunMe.sh path_to_your_video.mp4`

## Future work

* Much more sophisticated musical variation and structure (keep to a 2m track limitation)
* Assess video content with [Google's Cloud Vision](https://cloud.google.com/vision/) or [Amazon's Rekognition](https://aws.amazon.com/rekognition/), pick from a list of possible "genres" based on video content
* Productize the app in a web interface that accepts a video upload

## TODO

* Dockerize this app
* Replace local machine paths with relative paths
* Write documentation for TensorFlow/Magenta integration
