import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/bootstrap/crash_diagnostics.dart';

/// Sprint 102 / C1 — story-content redaction in diagnostic artifacts.
///
/// Contract: diagnostic artifacts are LOCAL-ONLY, but they must not carry
/// creative content (titles, character names) either. Because story content
/// is arbitrary text, detection is impossible by pattern; instead the
/// diagnostics sink accepts an injected set of sensitive terms captured from
/// the active project. Every captured field (message, signature, stack) is
/// scrubbed against those terms. Without injected terms behavior is
/// unchanged — the wiring slice is tracked separately.
void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('vs_story_redaction');
  });

  tearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      // Best-effort cleanup on Windows file-lock races; temp dirs are
      // cleaned by the OS anyway.
    }
  });

  CrashLogEntry captureOne(CrashDiagnostics diag) {
    diag.handleFlutterError(
      FlutterErrorDetails(
        exception: StateError('Scene failed: Rahasia Kastel Void'),
      ),
    );
    final file = dir.listSync().whereType<File>().single;
    return CrashLogEntry.fromJsonString(file.readAsStringSync());
  }

  test('injected story terms are scrubbed from message', () {
    final diag = CrashDiagnostics(
      directory: dir,
      sensitiveTerms: const ['Rahasia Kastel Void'],
    );

    final entry = captureOne(diag);

    expect(entry.message, isNot(contains('Rahasia Kastel Void')));
    expect(entry.message, contains('[STORY]'));
  });

  test('story terms are scrubbed case-insensitively', () {
    final diag = CrashDiagnostics(
      directory: dir,
      sensitiveTerms: const ['rahasia kastel void'],
    );

    final entry = captureOne(diag);

    expect(entry.message, isNot(contains('Rahasia Kastel Void')));
  });

  test('signature first line is scrubbed too', () {
    final diag = CrashDiagnostics(
      directory: dir,
      sensitiveTerms: const ['Rahasia Kastel Void'],
    );

    final entry = captureOne(diag);

    expect(entry.signature, isNot(contains('Rahasia Kastel Void')));
  });

  test('stack traces are scrubbed', () {
    final diag = CrashDiagnostics(
      directory: dir,
      sensitiveTerms: const ['Rahasia Kastel Void'],
    );

    diag.handleZoneError(
      Exception('boom'),
      StackTrace.fromString(
        '#0 loadScene (package:void_scriptor/story/Rahasia Kastel Void.dart:1)',
      ),
    );

    final file = dir.listSync().whereType<File>().single;
    final entry = CrashLogEntry.fromJsonString(file.readAsStringSync());
    expect(entry.stack, isNot(contains('Rahasia Kastel Void')));
  });

  test('empty term list leaves behavior unchanged', () {
    final diag = CrashDiagnostics(directory: dir);

    final entry = captureOne(diag);

    expect(entry.message, contains('Rahasia Kastel Void'));
  });

  test('secret redaction still composes with story redaction', () {
    final diag = CrashDiagnostics(
      directory: dir,
      sensitiveTerms: const ['Kastel'],
    );

    diag.handleFlutterError(
      FlutterErrorDetails(
        exception: StateError('api_key: supersecret42 at Kastel'),
      ),
    );

    final file = dir.listSync().whereType<File>().single;
    final raw = file.readAsStringSync();
    expect(raw, isNot(contains('supersecret42')));
    expect(raw, isNot(contains('Kastel')));
    expect(raw, contains('[REDACTED]'));
  });

  test('terms can be updated after construction and apply to next capture', () {
    final diag = CrashDiagnostics(directory: dir);

    diag.handleFlutterError(
      FlutterErrorDetails(exception: StateError('fail Mira')),
    );
    expect(
      CrashLogEntry.fromJsonString(
        dir.listSync().whereType<File>().single.readAsStringSync(),
      ).message,
      contains('Mira'),
    );

    diag.updateSensitiveTerms(const ['Mira']);
    diag.handleFlutterError(
      FlutterErrorDetails(exception: StateError('fail Mira again')),
    );

    final files = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    final newest = CrashLogEntry.fromJsonString(files.last.readAsStringSync());
    expect(newest.message, isNot(contains('Mira')));
  });
}
