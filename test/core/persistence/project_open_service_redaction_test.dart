import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/bootstrap/crash_diagnostics.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';
import 'package:void_scriptor/core/persistence/project_open_service.dart';

/// Sprint 102 / C1 wiring — opening a project feeds its manifest name and
/// tags into the crash-diagnostics sink so creative content can never reach
/// a diagnostic artifact via interpolated error messages.
void main() {
  late Directory tempDir;
  late Directory fakeRoot;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('open_service_c1');
    fakeRoot = Directory('${tempDir.path}/root')..createSync(recursive: true);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  CrashDiagnostics makeSink() =>
      CrashDiagnostics(directory: Directory('${fakeRoot.path}/crash'));

  ProjectManifest makeManifest(String id, String name, List<String> tags) =>
      ProjectManifest(
        // Schema 16 = format contract of release v1.0.1.
        schemaVersion: 16,
        id: id,
        name: name,
        description: '',
        projectVersion: '1',
        createdAt: DateTime.utc(2026, 8, 24),
        updatedAt: DateTime.utc(2026, 8, 24),
        appVersion: 'test',
        tags: tags,
        databaseFilename: '$id.vsdb',
      );

  test('is skipped when no diagnostics sink is provided', () {
    final service = ProjectOpenService.withRoot(fakeRoot);
    // No throw; behavior unchanged for callers that opt out.
    expect(
      () => service.noteOpened(makeManifest('p1', 'Saga', [])),
      returnsNormally,
    );
  });

  test('successful noteOpened feeds name and tags into the sink', () {
    final sink = makeSink();
    final service = ProjectOpenService.withRoot(fakeRoot, sink: sink);

    service.noteOpened(
      makeManifest('p1', 'Void Cube Saga', ['arc-one', 'Kastel']),
    );

    expect(sink.sensitiveTerms, containsAll(['Void Cube Saga', 'Kastel']));
  });

  test('opening a different project replaces the previous term set', () {
    final sink = makeSink();
    final service = ProjectOpenService.withRoot(fakeRoot, sink: sink);

    service.noteOpened(makeManifest('p1', 'Old Title', ['gone']));
    service.noteOpened(makeManifest('p2', 'New Title', ['kept']));

    expect(sink.sensitiveTerms, isNot(contains('Old Title')));
    expect(sink.sensitiveTerms, containsAll(['New Title', 'kept']));
  });
}
