import 'package:flutter/material.dart';

class RecordingState extends ChangeNotifier {
  int _startOfRecording = -1;
  // set genotes array... qlist

  int get startOfRecording => _startOfRecording;

  void setStartOfRecording(int startOfRecording) {
    _startOfRecording = startOfRecording;
    notifyListeners(); // Notify listeners about the update
  }

  Map<int, int> _timestamps = {};
  Map<int, int> get timestamps => _timestamps;

  void addTimestamp(int index, int timestamp) {
    _timestamps[index] = timestamp;
    notifyListeners();
  }
}
