import java.util.*;
import java.lang.Thread;

class TrackerThread extends Thread {
  Tracker[] trackers;
  volatile boolean cont;
  volatile boolean pause;
  TrackerThread(Tracker tracker) {
    trackers = new Tracker[] {
      tracker
    };
  }
  TrackerThread(Tracker[] mTrackers) {
    trackers = mTrackers;
  }
  public void run() {
    cont = true;
    long mMicros = (System.nanoTime() + 500) / 1000;
    for (Tracker t : trackers) {
      t.nextMicros = mMicros;
    }
    long micros = mMicros;
    while (cont) {
      long pMicros = micros;
      micros = (System.nanoTime() + 500) / 1000;
      for (Tracker t : trackers) {
        if (pause) {
          t.nextMicros += micros - pMicros;
        }
        else if (micros >= t.nextMicros) {
          t.singleExec();
        }
      }
    }
  }
  public void end() {
    cont = false;
  }
  public void playPause() {
    if (pause) {
      play();
    }
    else
    {
      pause();
    }
  }
  public void play() {
    pause = false;
    for (Tracker t : trackers) {
      if (t.channel.isPlaying()) {
        t.channel.osc.play();
      }
    }
  }
  public void pause() {
    pause = true;
    for (Tracker t : trackers) {
      t.channel.osc.stop();
    }
  }
}

class Tracker {
  long nextMicros;
  long defNoteMicros;
  int pos = -1;
  List<MusicCommand> commands;
  List<Integer> returnStack;
  Map<String, Integer> labels;
  PApplet applet;
  Channel channel;
  Tracker(PApplet mApplet, MusicCommand[] mCommands) {
    channel = new Channel();
    commands = new ArrayList<MusicCommand>();
    for (MusicCommand cmd : mCommands) {
      commands.add(cmd);
    }
    applet = mApplet;
    returnStack = new ArrayList<Integer>();
  }
  Tracker(PApplet mApplet, List<MusicCommand> mCommands) {
    commands = mCommands;
    channel = new Channel();
    applet = mApplet;
    returnStack = new ArrayList<Integer>();
  }
  Tracker(PApplet mApplet) {
    commands = new ArrayList<MusicCommand>();
    channel = new Channel();
    applet = mApplet;
    returnStack = new ArrayList<Integer>();
  }
  void calcLabels() {
    labels = new HashMap<String, Integer>();
    for (int i = 0; i < commands.size(); i++) {
      if (commands.get(i).type == MusicCommandType.Label) {
        labels.put((String)commands.get(i).value, i);
      }
    }
  }
  void add(MusicCommand command) {
    commands.add(command);
    if (command.micros == 0) {
      command.micros = defNoteMicros;
    }
    calcLabels();
  }
  void add(MusicCommand command, long micros) {
    command.micros = micros;
    commands.add(command);
    calcLabels();
  }
  void display(int lines, float x, float y, float w) {
    _display(lines, x, y, w);
  }
  void _display(int lines, float x, float y, float w) {
    fill(159);
    stroke(0);
    strokeWeight(1);
    rect(x, y, w, lines * 12 + 1);
    for (int i = 0; i < lines; i++) {
      int index = pos + i;
      if (i == 0) {
        fill(#00ffff);
        noStroke();
        rect(x + 1, y + 1, w - 1, 12);
      }
      else if ((index & 1) > 0) {
        fill(192);
        noStroke();
        rect(x + 1, y + 1 + i * 12, w - 1, 12);
      }
      fill(0);
      text(_gText(index), x + 3, y + 12 + i * 12);
    }
  }
  String _gText(int index) {
    if (index < 0 || index >= commands.size()) {
      return "";
    }
    MusicCommand cmd = commands.get(index);
    switch (cmd.type) {
      case Jump:
        return "Goto " + (String)cmd.value;
      case Label:
        return "Sub: " + (String)cmd.value;
      case Back:
        return "End sub";
      case SetAmp:
        return "Amp: " + Math.round((float)cmd.value * 100f) / 100f;
      case SetFreq:
        return "Freq: " + Math.round((float)cmd.value * 10f) / 10f;
      case Play:
        return "Play";
      case Stop:
        return "Stop";
      case SetInstrument:
        return "Instr: " + (String)cmd.value;
      case SetInstrumentPulseWave:
        return "Instr: PulseWave " + Math.round((float)cmd.value * 1000) / 1000f;
      case Call:
        return "Call " + (String)cmd.value;
      case Note:
        return "Note " + (String)cmd.value;
      case ADSR:
        return "ADSR";
      default:
        return "Error";
    }
  }
  void singleExec() {
    if (pos >= commands.size() - 1) {
      return;
    }
    pos ++;
    MusicCommand cmd = commands.get(pos);
    nextMicros += cmd.micros;
    switch (cmd.type) {
      case Note:
        channel.freq(note((String)cmd.value));
        return;
      case Call:
        returnStack.add(pos);
      case Jump:
        pos = labels.get(cmd.value) - 1;
      case Label:
        return;
      case Back:
        pos = returnStack.get(returnStack.size() - 1);
        returnStack.remove(returnStack.size() - 1);
        return;
      case SetAmp:
        channel.amp((float)cmd.value);
        return;
      case SetFreq:
        channel.freq((float)cmd.value);
        return;
      case Play:
        channel.play();
        return;
      case Stop:
        channel.stop();
        return;
      case SetInstrument:
        setInstr(cmd);
        return;
      case SetInstrumentPulseWave:
        Pulse p;
        channel.osc.setInstrument(p = new Pulse(applet));
        p.width(channel.pulseWidth = (float)cmd.value);
        channel.type = InstrumentType.PulseWave;
        return;
      case ADSR:
        Object[] arr = (Object[])cmd.value;
        channel.osc.attackMicros = (long)arr[0];
        channel.osc.decayMicros = (long)arr[1];
        channel.osc.sustainAmp = (float)arr[2];
        channel.osc.releaseMicros = (long)arr[3];
        return;
      case SetNoteTime:
        defNoteMicros = (long)cmd.value;
        return;
      default:
        //Error.
        return;
    }
  }
  void setInstr(MusicCommand command) {
    switch ((String)command.value) {
      default:
        //Invalid instrument.
        return;
      case("SineWave"):
        channel.osc.setInstrument(new SinOsc(applet));
        channel.type = InstrumentType.SineWave;
        return;
      case("SquareWave"):
        channel.osc.setInstrument(new SqrOsc(applet));
        channel.type = InstrumentType.SquareWave;
        return;
      case("TriangleWave"):
        channel.osc.setInstrument(new TriOsc(applet));
        channel.type = InstrumentType.TriangleWave;
        return;
      case("Sawtooth"):
        channel.osc.setInstrument(new SawOsc(applet));
        channel.type = InstrumentType.Sawtooth;
        return;
      case("WhiteNoise"):
        channel.osc.setInstrument(new WhiteNoise(applet));
        channel.type = InstrumentType.WhiteNoise;
        return;
    }
  }
}
