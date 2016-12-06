(

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
SynthDef(\mario, { |out, amp=0.1, freq=440|
 var snd;
 snd = LFPulse.ar(freq)!1;
 snd = snd * EnvGen.ar(Env.linen(0.001, 0.1, 0.03), doneAction:2);
 snd = GVerb.ar(snd, 20, 5);
 OffsetOut.ar([0,1], snd*amp);
}).add;
);

(
SynthDef(\first,
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
).add;
);

);
