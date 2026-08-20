enum SensorType { voice, gaze, gesture, bci, stylus, touch }

enum SensorRetention { none, session }

class SensorPrivacyPolicy {
  final Set<SensorType> _allowed = {};
  final Set<SensorType> _recording = {};
  SensorRetention _retention = SensorRetention.none;
  final List<Object> _records = [];

  bool localProcessingOnly = true;
  bool isAllowed(SensorType type) => _allowed.contains(type);
  bool get isRecording => _recording.isNotEmpty;
  List<Object> get records => List.unmodifiable(_records);

  void grant(SensorType type) => _allowed.add(type);
  void revoke(SensorType type) {
    _allowed.remove(type);
    _recording.remove(type);
  }

  void startRecording(SensorType type) {
    if (isAllowed(type)) _recording.add(type);
  }

  void stopRecording() => _recording.clear();
  void setLocalProcessingOnly(bool value) => localProcessingOnly = value;
  void setRetention(SensorRetention value) => _retention = value;
  void record(SensorType type, String payload) {
    if (_retention == SensorRetention.session && isAllowed(type)) {
      _records.add(type);
    }
  }
}

class RecordingIndicator {
  const RecordingIndicator(this.policy);
  final SensorPrivacyPolicy policy;
  bool get isRecording => policy.isRecording;
}
