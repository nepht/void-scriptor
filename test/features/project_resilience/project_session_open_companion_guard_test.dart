import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

// BUG-18 (bug-hunt run94, Referee verdict REAL BUG / Low): the open-failure
// catch deleted package.lockFile (.project.lock) whenever mode == readWrite,
// even when THIS session never wrote the companion (companionWritten false).
// A second session rejected by the live owner's session.lock therefore erased
// the owner's companion marker. The delete must be gated on companionWritten.
void main() {
  test(
    'rejected second open never deletes the live owner companion marker',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'void-bug18-owner-companion-',
      );
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Companion guard owner');

      // The live owner holds both markers; its recorded PID is this test
      // process, so dead-owner recovery must not touch the session marker.
      await package.sessionFile.writeAsString(
        '{"sessionId":"owner-session","projectId":"${package.projectId}",'
        '"processId":$pid,'
        '"openedAt":"2026-09-06T00:00:00.000Z"}',
        flush: true,
      );
      await package.lockFile.writeAsString(
        'owner companion marker',
        flush: true,
      );

      await expectLater(
        ProjectSessionManager().open(package),
        throwsA(isA<StateError>()),
      );

      expect(
        await package.sessionFile.exists(),
        isTrue,
        reason: 'a rejected open must not erase the live session marker',
      );
      expect(
        await package.lockFile.exists(),
        isTrue,
        reason: 'a rejected open must not erase the owner companion marker',
      );
    },
  );

  test(
    'failed open after this session wrote the companion cleans both markers',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'void-bug18-own-failure-',
      );
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Own failure cleanup');

      await expectLater(
        ProjectSessionManager(
          schemaVersionReader: (_) =>
              throw StateError('simulated pre-open failure'),
        ).open(package),
        throwsA(isA<StateError>()),
      );

      expect(
        await package.sessionFile.exists(),
        isFalse,
        reason: 'the acquired session marker must be released on failure',
      );
      expect(
        await package.lockFile.exists(),
        isFalse,
        reason: 'a companion written by THIS session must be cleaned up',
      );
    },
  );
}
