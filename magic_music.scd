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

 (
  SynthDef(\SOSkick,
   { arg out = 0, freq = 50, mod_freq = 5, mod_index = 5, sustain = 0.4, amp = 0.8, beater_noise_level = 0.025;
    var pitch_contour, drum_osc, drum_lpf, drum_env;
    var beater_source, beater_hpf, beater_lpf, lpf_cutoff_contour, beater_env;
    var kick_mix;
    pitch_contour = Line.kr(freq*2, freq, 0.02);
    drum_osc = PMOsc.ar(	pitch_contour,
     mod_freq,
     mod_index/1.3,
     mul: 1,
     add: 0);
    drum_lpf = LPF.ar(in: drum_osc, freq: 1000, mul: 1, add: 0);
    drum_env = drum_lpf * EnvGen.ar(Env.perc(0.005, sustain), 1.0, doneAction: 2);
    beater_source = WhiteNoise.ar(beater_noise_level);
    beater_hpf = HPF.ar(in: beater_source, freq: 500, mul: 1, add: 0);
    lpf_cutoff_contour = Line.kr(6000, 500, 0.03);
    beater_lpf = LPF.ar(in: beater_hpf, freq: lpf_cutoff_contour, mul: 1, add: 0);
    beater_env = beater_lpf * EnvGen.ar(Env.perc, 1.0, doneAction: 2);
    kick_mix = Mix.new([drum_env, beater_env]) * 2 * amp;
    Out.ar(out, [kick_mix, kick_mix])
   }
  ).add
 );

 (
 SynthDef(\SOStom,
  {arg out = 0, sustain = 0.4, drum_mode_level = 0.25,
   freq = 90, drum_timbre = 1.0, amp = 0.8;
   var drum_mode_sin_1, drum_mode_sin_2, drum_mode_pmosc, drum_mode_mix, drum_mode_env;
   var stick_noise, stick_env;
   var drum_reson, tom_mix;

   drum_mode_env = EnvGen.ar(Env.perc(0.005, sustain), 1.0, doneAction: 2);
   drum_mode_sin_1 = SinOsc.ar(freq*0.8, 0, drum_mode_env * 0.5);
   drum_mode_sin_2 = SinOsc.ar(freq, 0, drum_mode_env * 0.5);
   drum_mode_pmosc = PMOsc.ar(	Saw.ar(freq*0.9),
    freq*0.85,
    drum_timbre/1.3,
    mul: drum_mode_env*5,
    add: 0);
   drum_mode_mix = Mix.new([drum_mode_sin_1, drum_mode_sin_2, drum_mode_pmosc]) * drum_mode_level;
   stick_noise = Crackle.ar(2.01, 1);
   stick_env = EnvGen.ar(Env.perc(0.005, 0.01), 1.0) * 3;
   tom_mix = Mix.new([drum_mode_mix, stick_env]) * 2 * amp;
   Out.ar(out, [tom_mix, tom_mix])
  }
 ).add
 );

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
       numharm: numharm,
       mul: 0.75
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

    if(waitTimeI>1.0, {
     Synth(\first,[\adder,46,\numharm,1,\repeats,1,\roomsize,500,\revtime,20]);
    });

    i=i+1;
   };
  };
 });

 Pbind(
  \instrument, "SOSkick",
  \amp, 0.5,
  \freq, 50
 ).play(TempoClock.new(~mainBeat/2.0));

 /*Pbind(
  \instrument, "SOStom",
  \amp, 0.5,
  \sustain, 0.4,
  \drum_mode_level, 0.25,
  \freq, 90,
  \drum_timbre, 1.0,
  \amp, 0.8
 ).play(TempoClock.new(~mainBeat/8.0));*/

 (

  (
   {
    var exc, amp;
    amp = LFPulse.kr(~mainBeat,0,0.1,0.002);
    exc = LPZ1.ar(GrayNoise.ar([amp,amp]));
    Klank.ar(`[FloatArray.fill(4, { rrand(80.0,400.0) }),
     nil,
     FloatArray[1, 1, 1, 1]], exc);
   }.play;
  );

  (
   {
    var exc, amp;
    amp = LFPulse.kr(~mainBeat*2,0,0.1,0.002);
    exc = LPZ1.ar(GrayNoise.ar([amp,amp]));
    Klank.ar(`[FloatArray.fill(4, { rrand(80.0,400.0) }),
     nil,
     FloatArray[1, 1, 1, 1]], exc).abs;
   }.play;
  );

 );

 ~video = thisProcess.argv[1];
 ("ffplay -i -autoexit -showmode 0 -an " ++ ~video ).unixCmd;
 r.play;
 t.play;

});

);
