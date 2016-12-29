(
s = Server.local;
s.boot;
s.waitForBoot({

 s.recSampleFormat = "int16";
 s.recChannels = 1;
 s.recHeaderFormat = "WAV";

 ~outputPath = format("%/magic_music.wav", ~magicMusicPath);
 s.prepareForRecord(~outputPath);

 "MAIN BEAT".postln;
 ~mainBeat.postln;
 "TEMPO".postln;
 ~tempo.postln;

 TempoClock.default.tempo = ~tempo;

 this.executeFile(format("%/supercollider/generate_instruments.scd", ~magicMusicPath));

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
 ~outputVideoPath = format("%/videos/output.mp4", ~magicMusicPath);
 ("ffplay -i -autoexit -showmode 0 -an" + ~outputVideoPath).unixCmd;

});

);
