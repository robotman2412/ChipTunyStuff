void prepSynth(int mChannels) {
  if (trackerThread != null) {
    trackerThread.end();
  }
  if (adsrThread != null) {
    adsrThread.end();
  }
  trackerThread = new TrackerThread(trackers = new Tracker[mChannels]);
  channels = new Channel[mChannels];
  for (int i = 0; i < mChannels; i++) {
    trackers[i] = new Tracker(this);
    channels[i] = trackers[i].channel;
  }
  adsrThread = new ADSRThread();
}

void loadMusic(String path) {
  String[] file = loadStrings(path);
  Map<String, String> map = new HashMap<String, String>();
  for (int i = 0; i < file.length; i++) {
    String[] split = file[i].split(":");
    map.put(split[0], split[1]);
  }
  int channels = int(map.get("Channels"));
  //String name = map.get("Name");
  String channelScheme = map.get("Channel");
  prepSynth(channels);
  String mPath = new File(path).getParent();
  if (mPath.charAt(mPath.length() - 1) != '/') {
    mPath += "/";
  }
  for (int i = 0; i < channels; i++) {
    String[] channel = loadStrings(mPath + replace(channelScheme, '%', "" + i));
    for (String s : channel) {
      if (s != null && s.length() > 0) {
        trackers[i].add(parseCommand(s));
      }
    }
  }
}

void saveMusic(String path) {
  
}

String replace(String raw, char replace, String substitute) {
  String s = "";
  for (int i = 0; i < raw.length(); i++) {
    char c = raw.charAt(i);
    s += c != replace ? c : substitute;
  }
  return s;
}
