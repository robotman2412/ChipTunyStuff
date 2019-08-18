Map<String, Float> noteMap;

void setNotes() {
  noteMap = new HashMap<String, Float>();
  String[] rawNotes = loadStrings("notes.txt");
  for (String s : rawNotes) {
    if (s.charAt(0) == ' ') {
      s = s.substring(1);
    }
    String[] split = s.split("\t");
    String[] notes = split[0].split("/");
    float freq = float(split[1]);
    for (String note : notes) {
      noteMap.put(note.toLowerCase(), freq);
    }
  }
}

float note(String note) {
  return (float)noteMap.get(note.toLowerCase());
}
