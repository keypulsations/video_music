(

SynthDef(\acid, {
 arg out=0, gate=1, freq=440, amp=0.1, pan=0;
 var env1, env2, son, pitch;
 pitch = freq.cpsmidi;
 pitch = Lag.kr(pitch, 0.12 * (1-Trig.kr(gate, 0.001)) * gate);
 env1 = EnvGen.ar(Env.new([0, 1.0, 0, 0], [0.001, 2.0, 0.04], [0, -4, -4], 2), gate, amp);
 env2 = EnvGen.ar(Env.adsr(0.001, 0.8, 0, 0.8, 70, -4), gate);
 son = LFPulse.ar(pitch.midicps, 0.0, 0.51, 2, -1);

 son = RLPF.ar(son, (pitch + env2).midicps, 0.3);
 son = son * env1;

 Out.ar(out, Pan2.ar(son, pan));
},
metadata: (
 credit: "from 08091500Acid309 by_otophilia",
 tags: [\pitched, \acid, \phat, \subtractive]
)
).add;

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
},
metadata: (
 credit: "from 08091500Acid309 by_otophilia",
 tags: [\kick, \drum, \percussion]
)
).add;

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
},
metadata: (
 credit: "from 08091500Acid309 by_otophilia",
 tags: [\clap, \percussion]
)
).add;

(
// harmonic zither
// use mouse to strum strings
{
 var pitch, mousex, mousey, out, triggerSpacing, panSpacing;
 // harmonic series
 pitch = [ 50, 53.86, 57.02, 59.69, 62, 64.04, 65.86, 67.51, 69.02, 71.69, 72.88, 74 ];
 mousex = MouseX.kr;
 mousey = MouseY.kr;
 triggerSpacing = 0.5 / (pitch.size - 1);
 panSpacing = 1.5 / (pitch.size - 1);
 out = Mix.arFill(pitch.size, { arg i;
  var trigger, pluck, period, string;
  // place trigger points from 0.25 to 0.75
  trigger = HPZ1.kr(mousex > (0.25 + (i * triggerSpacing))).abs;
  pluck = PinkNoise.ar(Decay.kr(trigger, 0.05));
  period = pitch.at(i).midicps.reciprocal;
  string = CombL.ar(pluck, period, period, 8);
  Pan2.ar(string, i * panSpacing - 0.75);
 });
 LPF.ar(out, 12000);
 LeakDC.ar(out);
}.play;
);

/*(
b = Task({
var delta, dur, note;
dur = Prand([10, 15], inf).asStream;
note = Pwrand([145, 290], [0.8,0.2], inf).asStream;

while {
delta = dur.next;
delta.notNil
} {
Synth(\bass,[freq: note.next,decay:4]);
delta.yield;
}
}).play(quant:TempoClock.default.beats+1.0);
)*/

(
SynthDef(\pluck, {arg amp = 0.5, freq = 440, decay = 0.2, coef = 0.1;

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

 snd = snd.clip(-0.1,0.1);
 snd = FreeVerb.ar(snd, 0.5, 0.33, 0.15);

 Out.ar(0, [snd, snd]*4);
}).add;
)

);
