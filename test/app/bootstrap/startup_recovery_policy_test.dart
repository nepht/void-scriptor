import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/bootstrap/startup_recovery_policy.dart';

/// Sprint 101.9 — startup recovery decision engine. The policy decides the
/// recovery mode from persisted failure counts; it performs no I/O itself so
/// the wiring layer stays thin and testable.
void main() {
  late Directory tempDir;
  late File counterFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('vs_startup_rec_test');
    counterFile = File('${tempDir.path}${Platform.pathSeparator}state.json');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('StartupFailureCounter', () {
    test('a healthy shutdown clears the streak', () {
      final store = StartupFailureStore(file: counterFile);
      store.recordFailure();
      store.recordFailure();
      expect(store.read().consecutiveFailures, 2);

      store.recordHealthyShutdown();
      expect(store.read().consecutiveFailures, isZero);
      expect(counterFile.existsSync(), isTrue);
    });

    test('corrupt state file falls back to a clean slate, not a crash', () {
      counterFile.writeAsStringSync('{not json at all');

      final store = StartupFailureStore(file: counterFile);
      final state = store.read();

      expect(state.consecutiveFailures, isZero);
      // Reading must be side-effect free; writing repairs on next record.
      store.recordFailure();
      expect(store.read().consecutiveFailures, 1);
    });

    test('missing file reads as zero without creating it', () {
      final store = StartupFailureStore(file: counterFile);
      expect(store.read().consecutiveFailures, isZero);
      expect(counterFile.existsSync(), isFalse);
    });
  });

  group('StartupRecoveryPolicy.decide', () {
    test('first failure boots normally and records the failure', () {
      final outcome = StartupRecoveryPolicy.decide(
        readState: () => const StartupFailureState(consecutiveFailures: 0),
        writeState: (_) {},
      );

      expect(outcome.mode, StartupMode.normal);
      expect(outcome.failureCountAfterDecision, 1);
    });

    test('second consecutive failure drops into safe mode', () {
      final outcome = StartupRecoveryPolicy.decide(
        readState: () => const StartupFailureState(consecutiveFailures: 1),
        writeState: (_) {},
      );

      expect(outcome.mode, StartupMode.safe);
    });

    test('third consecutive failure offers full recovery mode', () {
      final outcome = StartupRecoveryPolicy.decide(
        readState: () => const StartupFailureState(consecutiveFailures: 2),
        writeState: (_) {},
      );

      expect(outcome.mode, StartupMode.recovery);
    });

    test(
      'fourth and later failures stay in recovery with diagnostics hint',
      () {
        final outcome = StartupRecoveryPolicy.decide(
          readState: () => const StartupFailureState(consecutiveFailures: 7),
          writeState: (_) {},
        );

        expect(outcome.mode, StartupMode.recovery);
        expect(outcome.suggestDiagnostics, isTrue);
      },
    );
  });

  group('configuration reset', () {
    test('reset() wipes persisted state for the configuration_reset mode', () {
      final store = StartupFailureStore(file: counterFile);
      store.recordFailure();
      store.recordFailure();

      store.reset();

      expect(
        StartupFailureStore(file: counterFile).read().consecutiveFailures,
        isZero,
      );
      expect(counterFile.existsSync(), isFalse);
    });
  });
}
