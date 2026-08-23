import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/bootstrap/crash_diagnostics.dart';
import 'package:void_scriptor/app/bootstrap/startup_recovery_policy.dart';

/// Sprint 101.17 — Privacy Regression.
///
/// Contract: Void Scriptor diagnostics are LOCAL-ONLY by design (see
/// release-contract-v1). The bootstrap/diagnostics layer must never transmit
/// crash or startup data anywhere: artifacts stay inside the injected local
/// directory, their contents carry no remote endpoints, and the layer gains
/// no networking dependency silently. AI providers elsewhere in the app are
/// explicitly user-initiated networking and are OUT OF SCOPE for this guard.
void main() {
  group('crash artifact containment', () {
    late Directory insideDir;
    late Directory outsideDir;

    setUp(() {
      insideDir = Directory.systemTemp.createTempSync('vs_privacy_inside');
      outsideDir = Directory.systemTemp.createTempSync('vs_privacy_outside');
    });

    tearDown(() {
      for (final dir in [insideDir, outsideDir]) {
        try {
          dir.deleteSync(recursive: true);
        } on FileSystemException {
          Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
            try {
              if (dir.existsSync()) dir.deleteSync(recursive: true);
            } catch (_) {}
          });
        }
      }
    });

    test('captured crashes land only inside the diagnostics directory', () {
      final diag = CrashDiagnostics(directory: insideDir);

      diag.handleFlutterError(
        FlutterErrorDetails(exception: StateError('render failed')),
      );
      diag.handleZoneError(Exception('zone failure'), StackTrace.current);

      expect(
        insideDir.listSync(recursive: true).whereType<File>(),
        hasLength(2),
      );
      // Nothing spilled into any sibling location.
      expect(outsideDir.listSync(recursive: true).whereType<File>(), isEmpty);
    });

    test('artifact schema stays fixed — no hidden telemetry fields', () {
      final diag = CrashDiagnostics(directory: insideDir);
      diag.handleZoneError(StateError('schema probe'), StackTrace.current);

      final entry = CrashLogEntry.fromJsonString(
        insideDir.listSync().whereType<File>().single.readAsStringSync(),
      );
      expect(entry.toJson().keys.toSet(), <String>{
        'id',
        'kind',
        'message',
        'signature',
        'stack',
        'zone',
        'occurredAt',
      });
    });

    test('artifact contents carry no remote endpoint or provider marker', () {
      final diag = CrashDiagnostics(directory: insideDir);
      diag.handleFlutterError(
        FlutterErrorDetails(exception: StateError('endpoint probe')),
      );
      diag.handleZoneError(Exception('endpoint probe 2'), StackTrace.current);

      final forbidden = RegExp(
        r'https?://|xmlHttpRequest|\bSocket\(|HttpClient|WebSocket|'
        r'sentry|firebase|crashlytics|api[_-]?key|bearer\s',
        caseSensitive: false,
      );
      for (final file in insideDir.listSync().whereType<File>()) {
        expect(
          forbidden.hasMatch(file.readAsStringSync()),
          isFalse,
          reason: '${file.path} contains a remote-endpoint marker',
        );
      }
    });

    test('startup failure state stays inside its own local file', () {
      final stateFile = File(
        '${insideDir.path}${Platform.pathSeparator}startup_state.json',
      );
      final store = StartupFailureStore(file: stateFile);

      store.recordFailure();
      store.recordFailure();
      expect(store.read().consecutiveFailures, 2);
      expect(stateFile.existsSync(), isTrue);

      // Exactly one artifact inside the injected dir, JSON with one key.
      final files = insideDir.listSync(recursive: true).whereType<File>();
      expect(files, hasLength(1));
      expect(
        StartupFailureState.fromJsonString(
          stateFile.readAsStringSync(),
        ).toJson().keys,
        equals(<String>['consecutiveFailures']),
      );

      store.reset();
      expect(stateFile.existsSync(), isFalse);
    });
  });

  group('bootstrap dependency surface', () {
    /// The only files allowed to implement capture/persistence plumbing.
    /// Scanned as text so a future network import cannot slip in silently.
    final bootstrapSources = [
      'lib/main.dart',
      'lib/app/bootstrap/app_diagnostics.dart',
      'lib/app/bootstrap/crash_diagnostics.dart',
      'lib/app/bootstrap/startup_recovery_policy.dart',
    ];

    final forbiddenDependency = RegExp(
      r"""import\s+['"](package:http|package:dio|package:socket|dart:mirrors)['"]"""
      r'|\bHttpClient\(|\bSocket\(|\bWebSocket\(|'
      r'\bsentry\b|firebase|crashlytics|mixpanel|amplitude|posthog',
      caseSensitive: false,
    );

    test('bootstrap sources import no networking or telemetry package', () {
      for (final path in bootstrapSources) {
        final source = File(path).readAsStringSync();
        expect(
          forbiddenDependency.hasMatch(source),
          isFalse,
          reason: '$path gained a networking/telemetry dependency',
        );
      }

      // The wiring root must keep calling prepareBootstrap() — the local
      // capture pipeline stays installed.
      expect(
        File('lib/main.dart').readAsStringSync(),
        contains('prepareBootstrap'),
      );
    });
  });
}
