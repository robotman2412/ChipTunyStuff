import processing.sound.*;

float freqScale = 10000;
float ampMult = 45;

Channel[] channels;
Tracker[] trackers;
TrackerThread trackerThread;
ADSRThread adsrThread;
Sound sound;

char micro = '\u00B5';

void setup() {
  size(499, 500);
  setNotes();
  //int time = 250000;
  //MusicCommand ADSR0 = CMD_ADSR(0, 50000, 0, 0);
  //MusicCommand ADSR1 = CMD_ADSR(0, 250000, 0, 0);
  //t = new Tracker(this);
  //t.add(ADSR1);
  //t.add(CMD_Label("Loop"));
  //t.add(CMD_SetInstrumentPulseWave(0.0125));//(0.025125));
  //t.add(CMD_SetFreq(100));
  //t.add(CMD_SetAmp(1));
  //t.add(CMD_Play(), time);
  //t.add(CMD_Stop());
  //t.add(CMD_SetInstrument("WhiteNoise"));
  //t.add(CMD_SetAmp(1));
  //t.add(CMD_Play(), time);
  //t.add(CMD_Stop());
  //t.add(ADSR0);
  //t.add(CMD_Play(), time);
  //t.add(CMD_Stop());
  //t.add(ADSR1);
  //t.add(CMD_Play(), time);
  //t.add(CMD_Stop());
  //t.add(CMD_Jump("Loop"));
  //th = new TrackerThread(t);
  //c = t.channel;
  //a = new ADSRThread();
  //a.ADSRs.add(c.osc);
  //c.osc.attackMicros = 0;
  //c.osc.decayMicros = 100000;
  //c.osc.sustainAmp = 0;
  //c.osc.releaseMicros = 0;
  //c.osc.volume = 0.125;
  prepSynth(1);
  loadMusic("/Users/mirte/Documents/Processing/SynthBoii/data/music.ptune");
  adsrThread.start();
  trackerThread.start();
  trackerThread.pause();
  sound = new Sound(this);
}

void draw() {
  background(255);
  for (int i = 0; i < channels.length; i++) {
    stroke(0);
    channels[i].display(0, i * 50, width, 50);
    trackers[i].display((height - channels.length * 50 - 2) / 12, i * width / channels.length, channels.length * 50, width / channels.length);
  }
}

void mousePressed() {
  trackerThread.playPause();
}
