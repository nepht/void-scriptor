// Sprint 110.7 — Derived Result Provenance contract.
//
// Scope: per Sprint 110 scope contract and R110-04, every derived result must
// preserve origin, confidence, assumptions, manual override, reason, and
// history. This file exercises the contract surface only. Implementation
// lives in .

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/derived_result_provenance.dart';

void main() {
  group('derived_result_provenance', () {
    test('captures origin, confidence, assumptions, and history', () {
      const result = DerivedResult<int>(
        value: 42,
        origin: ResultOrigin.simulation(
          sourceRevision: 'rev-1',
          generatedAtTick: 7,
        ),
        confidence: 0.8,
        assumptions: ['no rain', 'daylight'],
      );

      expect(result.value, 42);
      expect(result.confidence, 0.8);
      expect(result.assumptions, ['no rain', 'daylight']);
      expect(result.history, isEmpty);
      expect(result.manualOverride, isNull);
      expect(result.origin.sourceRevision, 'rev-1');
      expect(result.origin.generatedAtTick, 7);
    });

    test('manual override records reason and prior value in history', () {
      const baseline = DerivedResult<int>(
        value: 10,
        origin: ResultOrigin.simulation(
          sourceRevision: 'rev-1',
          generatedAtTick: 3,
        ),
        confidence: 0.5,
      );

      final overridden = baseline.applyManualOverride(
        value: 25,
        reason: 'writer intent',
        author: 'choirudin',
      );

      expect(overridden.value, 25);
      expect(overridden.manualOverride, isNotNull);
      expect(overridden.manualOverride!.reason, 'writer intent');
      expect(overridden.manualOverride!.author, 'choirudin');
      expect(overridden.manualOverride!.previousValue, 10);
      expect(overridden.history, hasLength(1));
      expect(overridden.history.first.fromValue, 10);
      expect(overridden.history.first.toValue, 25);
    });

    test('rejects confidence outside [0, 1] via validated factory', () {
      expect(
        () => DerivedResult<int>.validated(
          value: 1,
          origin: const ResultOrigin.simulation(
            sourceRevision: 'rev',
            generatedAtTick: 0,
          ),
          confidence: 1.2,
        ),
        throwsArgumentError,
      );

      expect(
        () => DerivedResult<int>.validated(
          value: 1,
          origin: const ResultOrigin.simulation(
            sourceRevision: 'rev',
            generatedAtTick: 0,
          ),
          confidence: -0.1,
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty reason on manual override', () {
      const baseline = DerivedResult<int>(
        value: 1,
        origin: ResultOrigin.simulation(
          sourceRevision: 'rev',
          generatedAtTick: 0,
        ),
        confidence: 0.0,
      );

      expect(
        () =>
            baseline.applyManualOverride(value: 2, reason: '   ', author: 'a'),
        throwsArgumentError,
      );
    });
  });
}
