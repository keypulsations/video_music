(
s.boot;

s.waitForBoot({

 this.executeFile("/Users/paulosetinsky/magic_music/supercollider/instruments.scd");

 ~mainBeat.postln;

 ~midiA = thisProcess.argv[2];
 ~midiB = thisProcess.argv[3];
 ~melodyA = SimpleMIDIFile.read(~midiA);
 ~melodyB = SimpleMIDIFile.read(~midiB);

 r = Routine({
  e = ~melodyA.p(\pluck).play(TempoClock.new(~mainBeat/2.0));
  32.wait;
  e.stop;
  e = ~melodyA.p(\pluck).play(TempoClock.new(~mainBeat/2.0));
  f = Pbind(\instrument, \kick, \amp, 0.35).play(TempoClock.new(~mainBeat/4.0));

  32.wait;
  e.stop;
  f.stop;
  e = ~melodyB.p(\pluck).play(TempoClock.new(~mainBeat/2.0));
  f = Pbind(\instrument, \kick, \amp, 0.35).play(TempoClock.new(~mainBeat/2.0));
  0.5.wait;
  f = Pbind(\instrument, \clap, \amp, 0.35).play(TempoClock.new(~mainBeat/4.0));

 });

 r.play(TempoClock.new(~mainBeat));

 (
  (
   {
    var exc, amp;
    amp = LFPulse.kr(~mainBeat*2,0,0.1,0.002) * EnvGen.kr(Env([0.1, 1], [~mainBeat * 5], curve: \exponential));
    exc = LPZ1.ar(GrayNoise.ar([amp,amp]));
    Klank.ar(`[FloatArray.fill(4, { 82.41 }),
     nil,
     FloatArray[1, 1, 1, 1]], exc);
   }.play;
  );
 );

  ("ffplay -i -autoexit -showmode 0 -an /Users/paulosetinsky/magic_music/videos/output.mp4").unixCmd;

});

);
