var kdeCalculate, beatRangeTolerance, filterBeats, calculateFitness, epanechnikovKernel, kde;

~rawOnsets = thisProcess.argv[0];
~onsets    = ~rawOnsets.split($,);
~onsets    = ~onsets.collect { |ot| ot.asFloat };
~durations = ~onsets.differentiate;
~video = thisProcess.argv[1];

// thanks to Nathan Ho and Dan Zink for help on this beat detection algorithm
kdeCalculate = {
 arg beats, guess = 2, tolerance = 2.5, binSize = 0.1, kernel = epanechnikovKernel, kernelWidth = 2;
 var beatTimes, peakKernel, kernelBeats, beatFit, kernelDiff = binSize * kernelWidth, minBeat, maxBeat;

 // Calculate beat range based on a guess and a given tolerance.
 #minBeat, maxBeat = beatRangeTolerance.(guess, tolerance, binSize * kernelWidth);

 // Filter out accidental/missed beats; also account for beats with a beat in between.
 beatTimes = filterBeats.(beats, minBeat, maxBeat);

 // Find the kernel with the highest KDE.
 peakKernel = kde.(beatTimes, binSize, kernel, kernelWidth).maxIndex * binSize;

 // Filter again.
 kernelBeats = beatTimes.select { |t| abs(peakKernel - t) < kernelDiff; };
 beatFit = kernelBeats.collect({ |t| calculateFitness.(kernelBeats, kernelBeats); });
 beatTimes[beatFit.minIndex];
};

kde = {
 arg beats, binSize, kernel, width = 1;
 var binNumber, kde, binRange;
 // Calculate how many bins (including headroom) we'll need.
 binNumber = (beats.maxItem / binSize).ceil + width + 1;
 kde = Array.fill(binNumber, {0});
 binRange = ((width.neg)..(width));

 beats.do {
  arg t;
  var centerBin;
  // Find the center bin and find kernel values for bins +/- width.
  centerBin = (t / binSize).round;
  (centerBin + binRange).do{
   arg position;
   kde[position] = kde[position] + (kernel).value((position * binSize - t) / width);
  };
 };
 kde;
};

beatRangeTolerance = {
 arg duration = 2, tolerance = 2.5, minBeat = 0;
 [max(duration * tolerance.reciprocal, minBeat), duration * tolerance];
};

filterBeats = {
 arg beats, minBeat = 1.5, maxBeat = 3;
 var beatTimes;
 beatTimes = beats.collect { |t, i| abs(t - beats.copyToEnd(i + 1)) }.flat;
 beatTimes.flatten.select  { |t| (( t >= minBeat) && (t <= maxBeat)); };
};

calculateFitness = {
 arg beats, dur;
 ((beats - dur) / dur).squared.sum;
};

epanechnikovKernel = { |n|
 0.75 * (1 - (n * n));
};

/* round ~mainBeat to nearest hundredth, as ffmpeg does not seem to be accurate beyond that*/
~mainBeat = kdeCalculate.(~onsets).round(0.01);

"main beat: ".postln;
~mainBeat.postln;

n = ("cd /Users/paulosetinsky/magic_music && ruby execute_quantize_video.rb" + ~rawOnsets + ~mainBeat + ~video).unixCmd;

t = true;
while({ t == true }) {
  if( n.pidRunning == false ) {
    this.executeFile("/Users/paulosetinsky/magic_music/supercollider/magic_music.scd").value([~mainBeat, "/Users/paulosetinsky/magic_music/videos/output.mp4"]);
    t = false;
  }
};

/*g = File("/Users/paulosetinsky/magic_music/video_onset_times/quantized_onset_times.txt","r");
~quantizedOnsetTimes = g.readAllString;
~quantizedOnsetTimes = ~quantizedOnsetTimes.split($,);
~quantizedOnsetTimes = ~quantizedOnsetTimes.collect { |ot| ot.asFloat };*/

/*this.executeFile("/Users/paulosetinsky/magic_music/supercollider/magic_music.scd").value([
  ~mainBeat,
  "/Users/paulosetinsky/magic_music/videos/output.mp4"
]);*/

/*this.executeFile("/Users/paulosetinsky/magic_music/supercollider/magic_music.scd").value([~mainBeat, "/Users/paulosetinsky/magic_music/videos/output.mp4"]);*/
