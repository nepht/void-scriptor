// Sprint 110.50 - Sprint Closure (domain aggregator).
//
// Closes Sprint 110 only after the six canonical DoD entries in
// `sprint_110.json:110.50.definition_of_done` are satisfied and the
// Alpha-2 acceptance gate (110.49) has produced a recorded decision.
//
// Canonical DoD keys (per `sprint_110.json:110.50`):
//   1. entry_gate_passed
//   2. 10_feature_contracts_resolved
//   3. cross_simulation_integration_verified
//   4. quality_reviews_complete
//   5. alpha_2_decision_recorded
//   6. remaining_risks_owned
//
// Decision rules:
//   - Any DoD entry with `passed=false` => DEFERRED
//   - alpha-2 report is blocked (Alpha2AcceptanceReport.isBlocked) => BLOCKED
//   - alpha-2 report decision is not GO (GO_WITH_DOCUMENTED_RISK/NO-GO) => DEFERRED
//   - Otherwise => CLOSED
//
// Domain-only, deterministic, no persistence, no UI, no wall clock,
// no locale, no random, no network.

library;

import 'alpha2_acceptance_gate.dart';

enum ClosureDecision { closed, deferred, blocked }

class ClosureDoD {
  const ClosureDoD({
    required this.key,
    required this.passed,
    required this.sourceRevision,
  });

  factory ClosureDoD.validated({
    required String key,
    required bool passed,
    required String sourceRevision,
  }) {
    if (key.isEmpty) {
      throw ArgumentError.value(key, 'key', 'must be non-empty');
    }
    if (sourceRevision.isEmpty) {
      throw ArgumentError.value(
        sourceRevision,
        'sourceRevision',
        'must be non-empty',
      );
    }
    return ClosureDoD(key: key, passed: passed, sourceRevision: sourceRevision);
  }

  final String key;
  final bool passed;
  final String sourceRevision;
}

class ClosureReport {
  const ClosureReport._({
    required this.decision,
    required this.passedCount,
    required this.totalCount,
    required this.unmetDoDKeys,
    required this.alpha2Summary,
    required this.summary,
  });

  final ClosureDecision decision;
  final int passedCount;
  final int totalCount;
  final List<String> unmetDoDKeys;
  final String alpha2Summary;
  final String summary;

  bool get isClosed => decision == ClosureDecision.closed;
  bool get isDeferred => decision == ClosureDecision.deferred;
  bool get isBlocked => decision == ClosureDecision.blocked;
}

class Sprint110Closure {
  Sprint110Closure._();

  static bool _alpha2IsFullGo(String summary) {
    if (!summary.startsWith('v1.2.0-alpha.2 decision=')) {
      return false;
    }
    final rest = summary.substring('v1.2.0-alpha.2 decision='.length);
    return rest.startsWith('GO;') || rest == 'GO';
  }

  static const List<String> dodKeys = <String>[
    'entry_gate_passed',
    '10_feature_contracts_resolved',
    'cross_simulation_integration_verified',
    'quality_reviews_complete',
    'alpha_2_decision_recorded',
    'remaining_risks_owned',
  ];

  static ClosureReport evaluate({
    required List<ClosureDoD> dod,
    required Alpha2AcceptanceReport alpha2Report,
  }) {
    if (dod.length != dodKeys.length) {
      throw ArgumentError.value(
        dod.length,
        'dod.length',
        'must equal canonical count of \${dodKeys.length}',
      );
    }

    final passedCount = dod.where((e) => e.passed).length;
    final unmet = <String>[
      for (final entry in dod)
        if (!entry.passed) entry.key,
    ];
    final alpha2Summary = alpha2Report.summary;

    ClosureDecision decision;
    if (alpha2Report.isBlocked) {
      decision = ClosureDecision.blocked;
    } else if (unmet.isNotEmpty || !_alpha2IsFullGo(alpha2Summary)) {
      decision = ClosureDecision.deferred;
    } else {
      decision = ClosureDecision.closed;
    }

    final buf = StringBuffer('sprint_110.50 closure ')
      ..write('decision=')
      ..write(decision.name.toUpperCase())
      ..write('; passed=')
      ..write(passedCount)
      ..write('/')
      ..write(dod.length)
      ..write('; alpha2=')
      ..write(alpha2Summary);

    return ClosureReport._(
      decision: decision,
      passedCount: passedCount,
      totalCount: dod.length,
      unmetDoDKeys: List<String>.unmodifiable(unmet),
      alpha2Summary: alpha2Summary,
      summary: buf.toString(),
    );
  }
}
