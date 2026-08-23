import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/bootstrap/crash_diagnostics.dart';

/// Sprint 101.3/101.8/101.9 — post-release crash capture with actionable
/// signatures. Deterministic: every test uses an injected temp directory.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('vs_crash_diag_test');
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } on FileSystemException {
      // Async flush race: retry once after a short delay.
      Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
        try {
          if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
        } catch (_) {}
      });
    }
  });

  group('CrashDiagnostics handler', () {
    test('writes a structured log file for captured flutter errors', () {
      final diag = CrashDiagnostics(directory: tempDir);

      diag.handleFlutterError(
        FlutterErrorDetails(
          exception: StateError('boom-render'),
          library: 'rendering',
          context: ErrorDescription('during build'),
        ),
      );

      final files = tempDir.listSync().whereType<File>().toList();
      expect(files, hasLength(1));
      expect(files.single.uri.pathSegments.last, startsWith('flutter-error-'));
      final decoded = CrashLogEntry.fromJsonString(
        files.single.readAsStringSync(),
      );
      expect(decoded.kind, 'flutter_error');
      expect(decoded.message, contains('boom-render'));
      expect(decoded.signature, isNotEmpty);
      expect(DateTime.tryParse(decoded.occurredAt), isNotNull);
    });

    test('writes a structured log file for zone errors including stack', () {
      final diag = CrashDiagnostics(directory: tempDir);

      diag.handleZoneError(
        Exception('disk full'),
        StackTrace.current,
        zone: 'root',
      );

      final files = tempDir.listSync().whereType<File>().toList();
      expect(files, hasLength(1));
      expect(files.single.uri.pathSegments.last, startsWith('zone-error-'));
      final decoded = CrashLogEntry.fromJsonString(
        files.single.readAsStringSync(),
      );
      expect(decoded.kind, 'zone_error');
      expect(decoded.message, contains('disk full'));
      expect(decoded.stack, isNotEmpty);
    });

    test('creates the target directory when missing', () {
      final nested = Directory(
        Platform.pathSeparator == '/'
            ? '${tempDir.path}/nested/deeper'
            : '${tempDir.path}\\nested\\deeper',
      );
      final diag = CrashDiagnostics(directory: nested);

      diag.handleZoneError(Exception('late'), StackTrace.current);

      expect(nested.existsSync(), isTrue);
    });
  });

  group('CrashSignature', () {
    test('groups identical error types and messages together', () {
      final a = CrashSignature.of(StateError('cache corrupted'), null);
      final b = CrashSignature.of(StateError('cache corrupted'), null);
      expect(a, b);
    });

    test('separates different types even with equal messages', () {
      final a = CrashSignature.of(StateError('same text'), null);
      final b = CrashSignature.of(ArgumentError('same text'), null);
      expect(a, isNot(b));
    });

    test('is stable across multiline messages (first line only)', () {
      final a = CrashSignature.of(StateError('line1\nline2'), null);
      final b = CrashSignature.of(StateError('line1\nother'), null);
      expect(a, b);
    });
  });

  group('install()', () {
    test('attaches global handlers and restore() reverts them', () {
      final previousFlutterOnError = FlutterError.onError;
      final previousDispatcherOnError = PlatformDispatcher.instance.onError;

      final diag = CrashDiagnostics(directory: tempDir);
      final restore = CrashDiagnostics.attach(diag);

      expect(FlutterError.onError, isNot(equals(previousFlutterOnError)));
      expect(
        PlatformDispatcher.instance.onError,
        isNot(equals(previousDispatcherOnError)),
      );

      // Simulate a dispatched flutter error flowing through the installed
      // handler into the diagnostics directory.
      FlutterError.onError!(
        FlutterErrorDetails(exception: StateError('via-onError')),
      );
      expect(tempDir.listSync().whereType<File>(), hasLength(1));

      restore();

      expect(FlutterError.onError, equals(previousFlutterOnError));
      expect(
        PlatformDispatcher.instance.onError,
        equals(previousDispatcherOnError),
      );
    });

    test(
      'install() is idempotent-safe: second attach chains, both restore',
      () {
        final original = FlutterError.onError;
        final diag = CrashDiagnostics(directory: tempDir);

        final restore1 = CrashDiagnostics.attach(diag);
        final restore2 = CrashDiagnostics.attach(diag);
        restore2();
        restore1();

        expect(FlutterError.onError, equals(original));
      },
    );
  });
}
