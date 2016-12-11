(
s.boot;

s.waitForBoot({

  ~tempo = case
  	{ ~mainBeat < 2 } { (2 -  ~mainBeat) * 4 }
  	{ ~mainBeat < 3 } { (4 -  ~mainBeat) }
    { ~mainBeat < 4 } { (2 - (~mainBeat/2)) * 4 }
    { ~mainBeat < 5 } { (8 - (~mainBeat)) / 2 };

 TempoClock.default.tempo = ~tempo;
 this.executeFile("/Users/paulosetinsky/magic_music/supercollider/instruments.scd");

 ~midiA = thisProcess.argv[2];
 ~midiB = thisProcess.argv[3];
 ~melodyA = SimpleMIDIFile.read(~midiA);
 ~melodyB = SimpleMIDIFile.read(~midiB);

/* ~quantizedDurations = ~quantizedOnsetTimes.differentiate;
 "QUANT DURS".postln;
 ~quantizedDurations.postln;

 i=0;
 r = Routine({
  loop {
   if(i<=~quantizedDurations.size) {
    var waitTime = ~quantizedDurations[i];
    waitTime.wait;
    Synth(\clap, [\amp, 0.4]);
    i=i+1;
   };
  };
 });*/

 x = {
  var exc, amp;
  amp = LFPulse.kr(~tempo*2,0.5,0.1,0.002) * EnvGen.kr(Env([0.1, 1], [~mainBeat * 10], curve: \exponential));
  exc = LPZ1.ar(GrayNoise.ar([amp,amp]));
  Klank.ar(`[FloatArray.fill(4, { 82.41 }),
   nil,
   FloatArray[1, 1, 1, 1]], exc);
 };

 t = Routine({
  ~melodyA.p(\pluck).play(TempoClock.new(~tempo));
  x.play;
  8.wait;
  Pbind(\instrument, \kick, \amp, 0.25).play(TempoClock.new(~tempo));
  16.wait;
  ~melodyB.p(\pluck).play(TempoClock.new(~tempo));
  1.wait;
  Pbind(\instrument, \clap, \amp, 0.25).play(TempoClock.new(~tempo));
 });

 ("ffplay -i -autoexit -showmode 0 -an /Users/paulosetinsky/magic_music/videos/output.mp4").unixCmd;
 t.play;
 // r.play(TempoClock.new(1));

});

);
