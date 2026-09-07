import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';

void main() {
  test(
    'release survives a transiently blocked marker delete within the retry window',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'void-lock-transient-',
      );
      addTearDown(() async {
        try {
          await root.delete(recursive: true);
        } catch (_) {}
      });
      final package = ProjectPackage(
        projectId: 'p-release-transient',
        root: root,
      );
      final lock = ProjectSessionLock(package);
      await lock.acquire(appVersion: 'test');

      // A concurrent release, antivirus scan, or indexer can briefly hold the
      // marker open on Windows; deleting while that handle exists fails with a
      // sharing violation. The hold here is short (15 ms) and must fall inside
      // the release retry window instead of surfacing a raw exception.
      final raf = await package.sessionFile.open(mode: FileMode.read);
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 15), raf.close),
      );
      await lock.release();

      expect(await package.sessionFile.exists(), isFalse);
    },
  );

  test(
    'release stays fail-closed when the marker delete stays blocked',
    () async {
      final root = await Directory.systemTemp.createTemp('void-lock-blocked-');
      addTearDown(() async {
        try {
          await root.delete(recursive: true);
        } catch (_) {}
      });
      final package = ProjectPackage(
        projectId: 'p-release-blocked',
        root: root,
      );
      final lock = ProjectSessionLock(package);
      await lock.acquire(appVersion: 'test');

      final raf = await package.sessionFile.open(mode: FileMode.read);
      try {
        await expectLater(lock.release(), throwsA(isA<FileSystemException>()));
      } finally {
        await raf.close();
      }

      // Once the blocking handle is gone, a retried release fully releases.
      await lock.release();
      expect(await package.sessionFile.exists(), isFalse);
    },
    // The blocked-delete precondition is staged with an open file handle:
    // Windows sharing violations block the marker delete, while POSIX
    // unlinks open files so the delete always succeeds there.
    skip: !Platform.isWindows,
  );
}
