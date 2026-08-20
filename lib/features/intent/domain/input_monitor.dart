class InputMonitorEvent {
  const InputMonitorEvent({
    required this.kind,
    required this.confidence,
    this.payload,
  });

  final String kind;
  final double confidence;
  final String? payload;
}

class InputMonitor {
  final List<InputMonitorEvent> _events = [];

  List<InputMonitorEvent> get events => List.unmodifiable(_events);

  void record({
    required String kind,
    required double confidence,
    String? payload,
  }) {
    _events.add(InputMonitorEvent(kind: kind, confidence: confidence));
  }
}
