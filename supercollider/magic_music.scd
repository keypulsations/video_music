(
s.boot;

s.waitForBoot({

 this.executeFile("/Users/paulosetinsky/magic_music/supercollider/beat_calculate.scd");
 this.executeFile("/Users/paulosetinsky/magic_music/supercollider/instruments.scd");
 f = thisProcess.argv[2];
 g = thisProcess.argv[3];
 m = SimpleMIDIFile.read(f);
 n = SimpleMIDIFile.read(g);
 i = 0;

 r = Routine({
  loop {
   if(i<~durations.size) {
    var waitTimeI = ~durations[i];
     /*Synth(\first,[\adder,51,\numharm,2,\repeats,1,\roomsize,500,\revtime,20]);*/
     Synth(\mario);
     waitTimeI.wait;
    i=i+1;
   };
  };
 });

 /*~durations[0].wait(TempoClock.new(~mainBeat));*/

 Pbind(
  \instrument, "SOSkick",
  \amp, 0.5,
  \freq, 50
 ).play(TempoClock.new(~mainBeat/2.0));

 /*m.p(\mario).play(TempoClock.new(~mainBeat/4.0));*/

 /*(
  (
   {
    var exc, amp;
    amp = LFPulse.kr(~mainBeat,0,0.1,0.002);
    exc = LPZ1.ar(GrayNoise.ar([amp,amp]));
    Klank.ar(`[FloatArray.fill(4, { 82.41 }),
     nil,
     FloatArray[1, 1, 1, 1]], exc);
   }.play;
  );

  (
   {
    var exc, amp;
    amp = LFPulse.kr(~mainBeat*2,0,0.1,0.002);
    exc = LPZ1.ar(GrayNoise.ar([amp,amp]));
    Klank.ar(`[FloatArray.fill(4, { 123.47 }),
     nil,
     FloatArray[1, 1, 1, 1]], exc).abs;
   }.play;
  );
 );*/

 /*~onsets[~onsets.size/2].wait(TempoClock.new(~mainBeat));*/
 /*n.p(\mario).play(TempoClock.new(~mainBeat/4.0));*/

 r.play;

 ~video = thisProcess.argv[1];
 ("ffplay -i -autoexit -showmode 0 -an " ++ ~video ).unixCmd;
});

);
