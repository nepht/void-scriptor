class LatencyMonitor {
  final List<Duration> _samples = [];

  Duration get average {
    if (_samples.isEmpty) return Duration.zero;
    final total = _samples.fold<int>(
      0,
      (sum, value) => sum + value.inMicroseconds,
    );
    return Duration(microseconds: total ~/ _samples.length);
  }

  void record(Duration latency) {
    if (latency.isNegative) return;
    _samples.add(latency);
  }
}
