(
s = Server.local;
s.boot;
s.waitForBoot({

 s.recSampleFormat = "int16";
 s.recChannels = 1;
 s.recHeaderFormat = "WAV";
 s.prepareForRecord("/Users/paulosetinsky/Desktop/magic_music.wav");

 "MAIN BEAT".postln;
 ~mainBeat.postln;
 "TEMPO".postln;
 ~tempo.postln;

 TempoClock.default.tempo = ~tempo;
 this.executeFile("/Users/paulosetinsky/magic_music/supercollider/instruments.scd");

 ~midiA = thisProcess.argv[2];
 ~midiB = thisProcess.argv[3];
 ~melodyA = SimpleMIDIFile.read(~midiA);
 ~melodyB = SimpleMIDIFile.read(~midiB);

 t = Routine({

  s.record;

  a = ~melodyA.p(\pluck).play(TempoClock.new(~tempo));
  8.wait;

  Pbind(\instrument, \kick, \amp, 0.25).play(TempoClock.new(~tempo));
  8.wait;

  a.stop;
  b = ~melodyB.p(\pluck).play(TempoClock.new(~tempo));
  8.wait;

  ~melodyA.p(\kick).play(TempoClock.new(~tempo/2));
  0.25.wait;
  ~melodyB.p(\clap).play(TempoClock.new(~tempo/2));

  7.75.wait;
  a = ~melodyA.p(\pluck).play(TempoClock.new(~tempo));
  Pbind(\instrument, \cymbal, \amp, 0.1).play(TempoClock.new(~tempo*2));

  40.wait;
  s.stopRecording;

 });

 t.play;
 ("ffplay -i -autoexit -showmode 0 -an /Users/paulosetinsky/magic_music/videos/output.mp4").unixCmd;

});

);