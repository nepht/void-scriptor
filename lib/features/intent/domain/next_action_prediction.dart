class IntentHistoryEntry {
  const IntentHistoryEntry({required this.intent, required this.targetId});

  final String intent;
  final String targetId;
}

class NextActionPrediction {
  const NextActionPrediction({required this.intent, required this.targetId});

  final String intent;
  final String targetId;

  @override
  bool operator ==(Object other) =>
      other is NextActionPrediction &&
      other.intent == intent &&
      other.targetId == targetId;

  @override
  int get hashCode => Object.hash(intent, targetId);
}

class NextActionPredictor {
  NextActionPrediction? predict(List<IntentHistoryEntry> history) {
    if (history.length < 2) return null;

    final previous = history[history.length - 2];
    final latest = history.last;
    if (previous.targetId != latest.targetId) return null;
    if (previous.intent != 'select' || latest.intent != 'edit') return null;

    return NextActionPrediction(intent: 'save', targetId: latest.targetId);
  }
}
