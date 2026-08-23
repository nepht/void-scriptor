import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/bootstrap/app_diagnostics.dart';
import 'package:void_scriptor/app/bootstrap/startup_recovery_policy.dart';

/// Sprint 101.3/101.9 — composition wiring of crash capture + startup
/// recovery counter, fully directory-injected for determinism.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('vs_boot_wiring_test');
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } on FileSystemException {
      Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
        try {
          if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
        } catch (_) {}
      });
    }
  });

  group('prepareBootstrap', () {
    test(
      'attaches handlers, records attempt, writes decision artifact',
      () async {
        final previousFlutterOnError = FlutterError.onError;

        final handle = await prepareBootstrap(rootOverride: tempDir);

        expect(FlutterError.onError, isNot(equals(previousFlutterOnError)));
        expect(handle.lastOutcome.mode, StartupMode.normal);
        expect(handle.lastOutcome.failureCountAfterDecision, 1);

        final stateFile = File('${tempDir.path}/state/startup.json');
        expect(stateFile.existsSync(), isTrue);
        expect(
          stateFile.readAsStringSync(),
          contains('"consecutiveFailures":1'),
        );

        final decisionFile = File(
          '${tempDir.path}/state/startup-decision.json',
        );
        expect(decisionFile.existsSync(), isTrue);
        expect(decisionFile.readAsStringSync(), contains('"mode":"normal"'));

        // Healthy shutdown clears the streak through the returned store.
        handle.store.recordHealthyShutdown();
        expect(
          File('${tempDir.path}/state/startup.json').readAsStringSync(),
          contains('"consecutiveFailures":0'),
        );

        handle.restoreDiagnostics();
        expect(FlutterError.onError, equals(previousFlutterOnError));
      },
    );

    test('second consecutive boot failure escalates to safe mode', () async {
      final first = await prepareBootstrap(rootOverride: tempDir);
      first.restoreDiagnostics();

      final second = await prepareBootstrap(rootOverride: tempDir);
      second.restoreDiagnostics();

      expect(second.lastOutcome.mode, StartupMode.safe);

      // A healthy shutdown resets; a third boot is normal again.
      second.store.recordHealthyShutdown();
      final third = await prepareBootstrap(rootOverride: tempDir);
      third.restoreDiagnostics();
      expect(third.lastOutcome.mode, StartupMode.normal);
    });

    test('decision artifact write failure does not block bootstrap', () async {
      // Occupy the decision-artifact path with a DIRECTORY so the artifact
      // write fails; bootstrap itself must still succeed.
      final blocker = Directory('${tempDir.path}/state/startup-decision.json');
      blocker.createSync(recursive: true);

      final handle = await prepareBootstrap(rootOverride: tempDir);
      handle.restoreDiagnostics();

      expect(handle.lastOutcome.mode, StartupMode.normal);
    });
  });

  group('BootstrapDirectories', () {
    test('under() lays out diagnostics/crash and state subdirectories', () {
      final dirs = BootstrapDirectories.under(tempDir);
      expect(
        dirs.crash.path,
        endsWith('diagnostics${Platform.pathSeparator}crash'),
      );
      expect(dirs.state.path, endsWith('state'));
    });
  });
}
