/// Slow query log (Step 26.67).
///
/// Repository/database wrappers log queries exceeding a threshold in
/// development builds. It must not log sensitive content excessively.
class SlowQueryEntry {
  const SlowQueryEntry({required this.query, required this.duration});

  final String query;
  final Duration duration;
}

class SlowQueryLog {
  SlowQueryLog({this.threshold = const Duration(milliseconds: 100)});

  final Duration threshold;
  final List<SlowQueryEntry> _entries = [];

  List<SlowQueryEntry> get entries => List.unmodifiable(_entries);

  Future<T> run<T>(String query, Future<T> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await operation();
    } finally {
      stopwatch.stop();
      if (stopwatch.elapsed >= threshold) {
        _entries.add(SlowQueryEntry(query: query, duration: stopwatch.elapsed));
      }
    }
  }

  void clear() => _entries.clear();
}
