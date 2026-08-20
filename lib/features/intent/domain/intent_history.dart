class IntentRecord {
  const IntentRecord({
    required this.intent,
    required this.targetId,
    this.payload,
  });

  final String intent;
  final String targetId;
  final String? payload;

  IntentRecord get redacted => IntentRecord(intent: intent, targetId: targetId);
}

class IntentHistory {
  IntentHistory({required this.maxEntries}) {
    if (maxEntries < 1) {
      throw ArgumentError.value(maxEntries, 'maxEntries');
    }
  }

  final int maxEntries;
  final List<IntentRecord> _entries = [];

  List<IntentRecord> get entries => List.unmodifiable(_entries);

  void add(IntentRecord record) {
    _entries.insert(0, record.redacted);
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }
  }

  void clear() => _entries.clear();
}
