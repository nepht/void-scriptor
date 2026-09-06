import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/bootstrap/app_diagnostics.dart';
import 'package:void_scriptor/app/bootstrap/startup_recovery_policy.dart';

/// Web bootstrap slice - prepareBootstrap must compose fully without any
/// dart:io dependency so the engine can render frame one in a browser.
/// These tests exercise the in-memory path through the @visibleForTesting
/// flag, mirroring what kIsWeb selects at runtime on the web target.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('prepareBootstrap (in-memory / web mode)', () {
    test('returns a working handle without touching the filesystem', () async {
      final handle = await prepareBootstrap(forceInMemory: true);

      expect(handle.lastOutcome.mode, StartupMode.normal);
      expect(handle.lastOutcome.failureCountAfterDecision, 1);
      expect(handle.stateFileWritten, isFalse);
    });

    test('store records failures and healthy shutdown in memory', () async {
      final handle = await prepareBootstrap(forceInMemory: true);

      // decide() already recorded this boot as attempt #1; a new failure
      // increments the streak on top of it.
      handle.store.recordFailure();
      expect(handle.store.read().consecutiveFailures, 2);

      handle.store.recordHealthyShutdown();
      expect(handle.store.read().consecutiveFailures, 0);

      handle.store.reset();
      expect(handle.store.read().consecutiveFailures, 0);
    });

    test(
      'web mode leaves global error handlers untouched and restore is safe',
      () async {
        final before = FlutterError.onError;
        final handle = await prepareBootstrap(forceInMemory: true);

        expect(FlutterError.onError, same(before));

        handle.restoreDiagnostics();
        expect(FlutterError.onError, same(before));
      },
    );

    test('file mode remains the default outside web', () async {
      expect(prepareBootstrapUsesFilesByDefault, isTrue);
    });
  });
}
