(
s.boot;

s.waitForBoot({

 this.executeFile("/Users/paulosetinsky/magic_music/supercollider/instruments.scd");

 ~mainBeat.postln;

 /*~midiA = thisProcess.argv[2];
 ~midiB = thisProcess.argv[3];
 ~melodyA = SimpleMIDIFile.read(~midiA);
 ~melodyB = SimpleMIDIFile.read(~midiB);*/

 /*i = 0;
 r = Routine({
  loop {
   if(i<~durations.size) {
    var waitTimeI = ~durations[i];
    Synth(\mario, [\freq, 300]);
    waitTimeI.wait;
    i=i+1;
   };
  };
 });*/

 /*~durations[0].wait(TempoClock.new(~mainBeat));*/
/*r.play;*/


 Pbind(
  \instrument, "SOSkick",
  \amp, 0.5,
  \freq, 50
 ).play(TempoClock.new(~mainBeat/2.0));

 Pbind(
  \instrument, "mario",
  \amp, 0.2,
  \freq, 600,
 ).play(TempoClock.new(~mainBeat/4.0));
 ("ffplay -i -autoexit -showmode 0 -an /Users/paulosetinsky/magic_music/videos/output.mp4").unixCmd;

 /*~melodyA.p(\mario).play(TempoClock.new(~mainBeat/4.0));*/

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
 /*~melodyB.p(\mario).play(TempoClock.new(~mainBeat/4.0));*/

});

);
