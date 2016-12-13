(

SynthDef(\kick, {
 arg out=0, amp=0.1, pan=0;
 var env0, env1, env1m, son;

 env0 =  EnvGen.ar(Env.new([0.5, 1, 0.5, 0], [0.005, 0.06, 0.26], [-4, -2, -4]), doneAction:2);
 env1 = EnvGen.ar(Env.new([110, 59, 29], [0.005, 0.29], [-4, -5]));
 env1m = env1.midicps;

 son = LFPulse.ar(env1m, 0, 0.5, 1, -0.5);
 son = son + WhiteNoise.ar(1);
 son = LPF.ar(son, env1m*1.5, env0);
 son = son + SinOsc.ar(env1m, 0.5, env0);

 son = son * 1.2;
 son = son.clip2(1);

 Out.ar(out, Pan2.ar(son * amp));
}).add;

SynthDef(\clap, {
 arg out=0, amp = 0.1, pan=0;
 var env1, env2, son, noise1, noise2;

 env1 = EnvGen.ar(Env.new([0, 1, 0, 1, 0, 1, 0, 1, 0], [0.001, 0.013, 0, 0.01, 0, 0.01, 0, 0.03], [0, -3, 0, -3, 0, -3, 0, -4]));
 env2 = EnvGen.ar(Env.new([0, 1, 0], [0.02, 0.3], [0, -4]), doneAction:2);

 noise1 = WhiteNoise.ar(env1);
 noise1 = HPF.ar(noise1, 600);
 noise1 = BPF.ar(noise1, 2000, 3);

 noise2 = WhiteNoise.ar(env2);
 noise2 = HPF.ar(noise2, 1000);
 noise2 = BPF.ar(noise2, 1200, 0.7, 0.7);

 son = noise1 + noise2;
 son = son * 2;
 son = son.softclip * amp;

 Out.ar(out, Pan2.ar(son, pan));
}).add;

SynthDef(\cymbal, {
 arg out=0, baseFreq = 300, time = 250, amp=0.1;
 //var freqs = [baseFreq, baseFreq*1.3420, baseFreq*1.2312, baseFreq*1.6532, baseFreq*1.9523, baseFreq*2.1523];
 //var freqs = [78.6, 140.44, 123.87, 219.4, 787.5, 531.3];
 //var freqs = [205.35, 254.29, 294.03, 304.41, 369.64, 522.71];
 var freqs = [205.35, 304.41, 369.64, 522.71, 540.54, 812.21];
 var signal, pulseEnv;

 pulseEnv = EnvGen.ar(Env.new([1.0, 0.6], [time], [-0.5]), timeScale:(1/1000));
 signal = Mix.new(LFPulse.ar(freqs * 4.09));
 signal = (BinaryOpUGen('==', signal, 6.0) * 0.6) + (BinaryOpUGen('==', signal, 2.0) * 0.2) + (BinaryOpUGen('==', signal, 1.0) * 0.9); // XOR
 signal = (signal * pulseEnv) + (Mix.new(LFPulse.ar(freqs, width:0.55)) * 0.9);
 signal = RLPF.ar(signal, 7000, 0.6);
 signal = RHPF.ar(signal, 6800, 1.5);
 signal = RHPF.ar(signal, 6800, 1.5);
 signal = RHPF.ar(signal, 1200, 1.5);
 signal = signal + FreeVerb.ar(signal);
 signal = signal * EnvGen.ar(Env.new([0, 1, 0.4, 0, 0], [2, time, 50, 500], [0, -0.5, 0, -50]), timeScale:(1/1000), doneAction:2);
 signal = [signal, DelayN.ar(signal, 0.005, 0.005)];
 OffsetOut.ar(out, signal*4*amp);
}).add;

(
SynthDef(\pluck, {arg amp = 0.5, freq = 440, decay = 0.25, coef = 0.5;

 var env, snd;
 env = EnvGen.kr(Env.linen(0, decay, 0), doneAction: 2);

 freq = freq/2.0;

 snd = Pluck.ar(
  in: WhiteNoise.ar(amp),
  trig: Impulse.kr(0),
  maxdelaytime: 0.1,
  delaytime: freq.reciprocal,
  decaytime: decay,
  coef: coef
 );

 snd = snd.distort;
 snd = FreeVerb.ar(snd, 0.7, 0.5, 0.3);

 Out.ar(0, [snd, snd]*4);
}).add;
);

/*(
SynthDef(\hum, { arg gate=1,fadeInTime=1,freq=2;
 var exc, amp;
 amp = LFPulse.kr(freq,-0.25,0.1,0.002);
 exc = LPZ1.ar(WhiteNoise.ar([amp,amp]));
 o = Klank.ar(`[FloatArray.fill(4, { rand(80,84)}), nil, FloatArray[1, 1, 1, 1]], exc);
 Out.ar(0, o * Env.asr(0.001,1,0.5).kr(2,gate));
}).add;
);*/

);
