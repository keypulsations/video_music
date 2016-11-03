(
s.boot;
s.waitForBoot({
 var kdeCalculate, beatRangeTolerance, filterBeats, calculateFitness, epanechnikovKernel, kde, base;

 base = Pbind(\amp, 0.2);
 i = rrand(1,9);
 (
  f = format("/Users/paulosetinsky/ai/magenta/tmp/attention_rnn/generated/2016-11-02_193203_0%.mid", i);
  m = SimpleMIDIFile.read(f);
 );

 ~onsets = thisProcess.argv[0];
 ~onsets = ~onsets.split($,);
 ~onsets = ~onsets.collect { |it| it.asFloat };
 ~durations = ~onsets.differentiate;

 // thanks to Nathan Ho and Dan Zink for this beat detection algorithm
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
  beatTimes.flatten.select { |t| (( t >= minBeat) && (t <= maxBeat));};
 };

 calculateFitness = {
  arg beats, dur;
  ((beats - dur) / dur).squared.sum;
 };

 epanechnikovKernel = { |n|
  0.75 * (1 - (n * n));
 };

 ~mainBeat = kdeCalculate.(~onsets);

 SynthDef("kick", {arg out = 0, amp = 0.3, sinfreq = 60, glissf = 0.9, att = 0.01, rel = 0.45, pan = 0;
  var env, snd, ramp;
  env = Env.perc(att, rel, amp).kr(doneAction: 2);
  ramp = XLine.kr(
   start: sinfreq,
   end: sinfreq * glissf,
   dur: rel
  );
  snd = SinOsc.ar(freq: ramp, mul: env);
  snd = Pan2.ar(snd, pan);
  Out.ar(out, snd);
 }).add;

SynthDef(\tri, {|out= 0 freq = 440 amp = 0.1 gate=1 lforate = 10 lfowidth= 0.0 cutoff= 100 rq=0.5 pan=0.0|

 var osc1, osc2, vibrato, filter, env;

 vibrato = SinOsc.ar(lforate,Rand(0,2.0));

 osc1 = Saw.ar(freq*(1.0+(lfowidth*vibrato)),0.75);

 osc2 = Mix(LFTri.ar((freq.cpsmidi+[11.9,12.1]).midicps));

 filter = (osc1+(osc2*0.5))*0.5; //no filter version
 /*filter = RHPF.ar((osc1+(osc2*0.5))*0.5,cutoff,rq);*/

 env = EnvGen.ar(Env.adsr(0.01,0.1,1.0,0.5),gate,doneAction:2);

 Out.ar(out,Pan2.ar(filter*env*amp,pan));

}).add;

 (
  SynthDef.new(\first,
   {
    arg numharm,adder,repeats,roomsize,revtime;
    var outArray;
    outArray = [
     GVerb.ar(
      in: Blip.ar(
       freq:
       Duty.kr(
        dur: 1/[1,2,4,8],
        reset: 0,
        level: Dseq(
         list: [19,17,12,7,3,0] + adder,
         repeats: repeats
        ),
        doneAction: 2
       ).midicps*[1,4,8],
       numharm: numharm
      ).sum,
      roomsize: roomsize,
      revtime: revtime

     )
    ];

    Out.ar([0,1], Pan2.ar(outArray,0,0.02));

   }
  ).send(s);
 );

 i=0;
 r = Routine({
  loop {
   if(i<~durations.size) {
    var waitTimeI = ~durations[i];
    waitTimeI.wait;

    Synth(\first,[\adder,61,\numharm,1,\repeats,1,\roomsize,200,\revtime,1]);

    i=i+1;
   };
  };
 });


 "MAINBEAT".postln;
 ~mainBeat.postln;
 m.p(\tri).play(TempoClock.new(~mainBeat/8.0));

 Pbind(
  \instrument, "kick",
  \amp, 0.5
 ).play(TempoClock.new(~mainBeat/2.0));

 ~video = thisProcess.argv[1];

 ("ffplay -i -autoexit -showmode 0 -an " ++ ~video ).unixCmd;

 r.play;
 t.play;

});

);
