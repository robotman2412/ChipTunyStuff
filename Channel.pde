enum MusicCommandType {
  Jump, //Jump to label in track
  Call, //Push address and jump
  Back, //Return (i.e. pop address)
  SetInstrument, //Set channel instrument type
  SetInstrumentPulseWave, //Set instrument to pulse wave and set pulse width
  SetAmp, //Set channel amplitude
  SetFreq, //Set channel frequency
  Play, //Start playing on channel
  Stop, //Stop playing on channel
  Label, //Label referenced by Jump and Call
  Note, //Play frequency for music note (with default time if not specified otherwise)
  ADSR, //Set ADSR envelope
  SetNoteTime //Set default note duration
}

MusicCommand parseCommand(String raw) {
  long time = 0;
  if (raw.charAt(0) == 'T') {
    time = Long.parseLong(raw.substring(1, raw.indexOf(':')));
    raw = raw.substring(raw.indexOf(':') + 1);
  }
  MusicCommand cmd = _parseCommand(raw);
  cmd.micros = time;
  return cmd;
}

MusicCommand _parseCommand(String raw) {
  String[] split = raw.split(":");
  switch(raw) {
    case("Back"):
      return CMD_Back();
    case("Play"):
      return CMD_Play();
    case("Stop"):
      return CMD_Stop();
  }
  if (split.length == 1) {
    return CMD_Note(raw);
  }
  switch(split[0]) {
    case("ADSR"):
      split = split[1].split(",");
      return CMD_ADSR(Long.parseLong(split[0]), Long.parseLong(split[1]), float(split[2]), Long.parseLong(split[3]));
    case("Jump"):
      return CMD_Jump(split[1]);
    case("Note"):
      return CMD_Note(split[1]);
    case("Call"):
      return CMD_Call(split[1]);
    case("Label"):
      return CMD_Label(split[1]);
    case("SetInstrument"):
      return CMD_SetInstrument(split[1]);
    case("SetInstrumentPulseWave"):
      return CMD_SetInstrumentPulseWave(float(split[1]));
    case("SetAmp"):
      return CMD_SetAmp(float(split[1]));
    case("SetFreq"):
      return CMD_SetFreq(float(split[1]));
    case("SetNoteTime"):
      return CMD_SetNoteTime(Long.parseLong(split[1]));
    case("Back"):
      return CMD_Back();
    case("Play"):
      return CMD_Play();
    case("Stop"):
      return CMD_Stop();
  }
  println(raw);
  return null;
}

MusicCommand CMD_ADSR(long attackMicros, long decayMicros, float sustainLevel, long releaseMicros) {
  return new MusicCommand(MusicCommandType.ADSR, new Object[] {attackMicros, decayMicros, sustainLevel, releaseMicros});
}

MusicCommand CMD_Jump(String label) {
  return new MusicCommand(MusicCommandType.Jump, label);
}

MusicCommand CMD_Note(String note) {
  return new MusicCommand(MusicCommandType.Note, note);
}

MusicCommand CMD_Call(String label) {
  return new MusicCommand(MusicCommandType.Call, label);
}

MusicCommand CMD_Label(String label) {
  return new MusicCommand(MusicCommandType.Label, label);
}

MusicCommand CMD_SetInstrument(String inst) {
  return new MusicCommand(MusicCommandType.SetInstrument, inst);
}

MusicCommand CMD_SetInstrumentPulseWave(float pulseWidth) {
  return new MusicCommand(MusicCommandType.SetInstrumentPulseWave, pulseWidth);
}

MusicCommand CMD_SetAmp(float amp) {
  return new MusicCommand(MusicCommandType.SetAmp, amp);
}

MusicCommand CMD_SetFreq(float freq) {
  return new MusicCommand(MusicCommandType.SetFreq, freq);
}

MusicCommand CMD_SetNoteTime(long time) {
  return new MusicCommand(MusicCommandType.SetNoteTime, time);
}

MusicCommand CMD_Back() {
  return new MusicCommand(MusicCommandType.Back, null);
}

MusicCommand CMD_Play() {
  return new MusicCommand(MusicCommandType.Play, null);
}

MusicCommand CMD_Stop() {
  return new MusicCommand(MusicCommandType.Stop, null);
}

class MusicCommand {
  MusicCommandType type;
  Object value;
  long micros;
  MusicCommand(MusicCommandType mType, Object mValue) {
    type = mType;
    value = mValue;
  }
}

enum InstrumentType {
  SquareWave,
  SineWave,
  Sawtooth,
  TriangleWave,
  WhiteNoise,
  PulseWave
}

class Channel {
  InstrumentType type;
  ADSRManager osc;
  float freq = 1;
  float amp = 1;
  float dispOffs;
  float pulseWidth;
  boolean isPlaying;
  Channel() {
    osc = new ADSRManager();
  }
  void freq(float mFreq) {
    osc.freq(freq = mFreq);
  }
  void amp(float mAmp) {
    osc.amp(amp = mAmp);
  }
  void play() {
    isPlaying = true;
    osc.play();
  }
  void stop() {
    osc.stop();
    isPlaying = false;
  }
  boolean isPlaying() {
    return isPlaying;
  }
  float dispExt(float rot) {
    if (!osc._isPlaying() || type == null) {
      return 0;
    }
    switch(type) {
      case SquareWave:
        pulseWidth = 0.5;
      case PulseWave:
        return rot > pulseWidth ? 1 : -1;
      case SineWave:
        return cos(rot * TAU);
      case Sawtooth:
        return rot * 2f - 1f;
      case TriangleWave:
        return rot > 0.5 ? 1 - rot : rot;
      case WhiteNoise:
        return random(2) - 1f;
    }
    return 0;
  }
  void display(float x, float y, float w, float h) {
    if (type == InstrumentType.WhiteNoise) {
      //dispWhtNoise(x, y, w, h);
      //return;
    }
    float mPy = 0;
    float rots = freqScale / freq / w;
    for (int i = 0; i < w - x; i++) {
      float mY = y + h / 2f + dispExt(dispOffs) * osc.amp * h / 2f;
      dispOffs += rots;
      if (dispOffs > 1) {
        dispOffs -= 1f;
      }
      if (i > 0) {
        line(i + x - 1, mPy, i + x, mY);
      }
      mPy = mY;
    }
  }
}

class ADSRManager {
  long attackMicros;
  long decayMicros;
  float sustainAmp;
  long releaseMicros;
  WhiteNoise noise;
  Oscillator<?> osc;
  boolean isPlaying;
  long playMicros;
  float maxAmp = 1;
  float amp;
  float volume = 1; //multiplied by amp
  ADSRManager() {
    simple();
  }
  ADSRManager(Oscillator<?> mOsc) {
    osc = mOsc;
    simple();
  }
  void setInstrument(Oscillator<?> mOsc) {
    if (noise != null) {
      if (noise.isPlaying()) {
        noise.stop();
      }
      noise = null;
    }
    osc = mOsc;
  }
  void setInstrument(WhiteNoise mNoise) {
    if (noise == null && osc != null) {
      if (osc.isPlaying()) {
        osc.stop();
      }
      osc = null;
    }
    noise = mNoise;
  }
  void simple() {
    attackMicros = 0;
    decayMicros = 0;
    sustainAmp = 1;
    releaseMicros = 0;
  }
  void freq(float freq) {
    if (noise == null && osc != null) {
      osc.freq(freq);
    }
  }
  void amp(float mMaxAmp) {
    maxAmp = mMaxAmp;
  }
  void _amp(float mAmp) {
    amp = mAmp;
    if (noise != null) {
      noise.amp(amp * volume);
    }
    else if (osc != null) {
      osc.amp(amp * volume);
    }
  }
  void play() {
    isPlaying = true;
    playMicros = (System.nanoTime() + 500) / 1000;
    if (_isPlaying()) {
      return;
    }
    if (noise != null) {
      noise.play();
    }
    else if (osc != null) {
      osc.play();
    }
  }
  void stop() {
    isPlaying = false;
    playMicros = (System.nanoTime() + 500) / 1000;
  }
  void doADSR() {
    long micros = (System.nanoTime() + 500) / 1000;
    if (isPlaying) {
      if (attackMicros > 0 && playMicros + attackMicros > micros) {
        _amp(maxAmp * (float)((double)(micros - playMicros) / attackMicros));
       }
      else if (decayMicros > 0 && playMicros + attackMicros + decayMicros > micros) {
        _amp(maxAmp * sustainAmp + (maxAmp - sustainAmp * maxAmp) * (float)(1d - ((double)(micros - playMicros - attackMicros) / decayMicros)));
      }
      else
      {
        _amp(maxAmp * sustainAmp);
      }
    }
    else
    {
      if (releaseMicros > 0 && playMicros + releaseMicros > micros) {
        _amp(maxAmp * sustainAmp * (float)(1d - (double)(micros - playMicros) / releaseMicros));
        println("release:", amp);
      }
      else if (_isPlaying()) {
        _stop();
      }
    }
  }
  void _stop() {
    if (noise != null) {
      noise.stop();
    }
    else if (osc != null) {
      osc.stop();
    }
  }
  boolean _isPlaying() {
    if (noise != null) {
      return noise.isPlaying();
    }
    else if (osc != null) {
      return osc.isPlaying();
    }
    else
    {
      return false;
    }
  }
}

class ADSRThread extends Thread {
  volatile boolean cont;
  List<ADSRManager> ADSRs;
  ADSRThread() {
    ADSRs = new ArrayList<ADSRManager>();
  }
  public void run() {
    setPriority(MAX_PRIORITY);
    cont = true;
    while (cont) {
      for (ADSRManager m : ADSRs) {
        m.doADSR();
      }
      try {
        Thread.sleep(0, 1);
      } catch(Exception e) {
        
      }
    }
  }
  public void end() {
    cont = false;
  }
}

// \u00B5
