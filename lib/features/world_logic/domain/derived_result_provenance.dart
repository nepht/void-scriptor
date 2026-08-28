// Sprint 110.7 — Derived Result Provenance contract.
//
// Every derived world result carries its origin (source revision + tick),
// a bounded confidence in [0, 1], the assumptions used during derivation,
// an optional manual override (with reason and author), and a full
// history of prior values. Manual overrides append a history entry but
// never mutate the original baseline.

library;

class ResultOrigin {
  const ResultOrigin._({
    required this.sourceRevision,
    required this.generatedAtTick,
    required this.kind,
  });

  const ResultOrigin.simulation({
    required String sourceRevision,
    required int generatedAtTick,
  }) : this._(
         sourceRevision: sourceRevision,
         generatedAtTick: generatedAtTick,
         kind: ResultOriginKind.simulation,
       );

  const ResultOrigin.manual({
    required String sourceRevision,
    required int generatedAtTick,
  }) : this._(
         sourceRevision: sourceRevision,
         generatedAtTick: generatedAtTick,
         kind: ResultOriginKind.manual,
       );

  final String sourceRevision;
  final int generatedAtTick;
  final ResultOriginKind kind;
}

enum ResultOriginKind { simulation, manual }

class ManualOverride {
  const ManualOverride({
    required this.reason,
    required this.author,
    required this.previousValue,
  });

  final String reason;
  final String author;
  final Object? previousValue;
}

class ResultHistoryEntry {
  const ResultHistoryEntry({
    required this.fromValue,
    required this.toValue,
    required this.reason,
    required this.author,
    required this.atTick,
  });

  final Object? fromValue;
  final Object? toValue;
  final String reason;
  final String author;
  final int atTick;
}

class DerivedResult<T> {
  const DerivedResult({
    required this.value,
    required this.origin,
    required this.confidence,
    this.assumptions = const [],
    this.history = const [],
    this.manualOverride,
  }) : assert(
         confidence >= 0 && confidence <= 1,
         'confidence must be within [0, 1]',
       );

  factory DerivedResult.validated({
    required T value,
    required ResultOrigin origin,
    required double confidence,
    List<String> assumptions = const [],
    List<ResultHistoryEntry> history = const [],
    ManualOverride? manualOverride,
  }) {
    if (confidence < 0 || confidence > 1) {
      throw ArgumentError.value(
        confidence,
        'confidence',
        'confidence must be within [0, 1]',
      );
    }
    return DerivedResult<T>(
      value: value,
      origin: origin,
      confidence: confidence,
      assumptions: assumptions,
      history: history,
      manualOverride: manualOverride,
    );
  }

  final T value;
  final ResultOrigin origin;
  final double confidence;
  final List<String> assumptions;
  final List<ResultHistoryEntry> history;
  final ManualOverride? manualOverride;

  DerivedResult<T> applyManualOverride({
    required T value,
    required String reason,
    required String author,
    int atTick = 0,
  }) {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'reason is required');
    }
    final entry = ResultHistoryEntry(
      fromValue: this.value,
      toValue: value,
      reason: trimmed,
      author: author,
      atTick: atTick,
    );
    return DerivedResult<T>(
      value: value,
      origin: ResultOrigin.manual(
        sourceRevision: origin.sourceRevision,
        generatedAtTick: origin.generatedAtTick,
      ),
      confidence: confidence,
      assumptions: assumptions,
      history: [...history, entry],
      manualOverride: ManualOverride(
        reason: trimmed,
        author: author,
        previousValue: this.value,
      ),
    );
  }
}
