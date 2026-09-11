import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/security/application/project_lock_service.dart';
import 'package:void_scriptor/core/security/crypto/encryption_cipher.dart';
import 'package:void_scriptor/core/security/crypto/key_derivation.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

// hunt run197 BUG-5 + BUG-6 (Referee verdicts REAL BUG / Medium), both in
// project_session_manager.dart.
// BUG-5: _close() ran teardown sequentially with no per-step guard, and
// close() memoized the FAILED future, so a lock.release() failure skipped the
// companion .project.lock delete forever and no later close() could finish.
// BUG-6: open()'s catch awaited lock.release() and the unguarded
// lockFile.delete() BEFORE the guarded database close, so a transient
// errno-32 hold replaced the original ProjectLockedException and skipped the
// rest of the cleanup.
// The trigger is the repo's documented errno-32 sharing-violation class,
// staged the same way as session_lock_release_transient_block_test.dart: a
// live read handle on session.lock outlasts the bounded release retry window.
void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('void-run199-bug56-');
  });
  tearDown(() async {
    try {
      await root.delete(recursive: true);
    } on FileSystemException {
      // A leaked SQLite handle can keep the tree busy; %TEMP% is disposable.
    }
  });

  test(
    'BUG-5 a blocked session-marker release does not skip the companion '
    'delete and a later close() finishes the remaining step',
    () async {
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Bug5 teardown');
      final session = await ProjectSessionManager().open(package);
      expect(await package.lockFile.exists(), isTrue);

      final raf = await package.sessionFile.open(mode: FileMode.read);
      try {
        // The hold outlasts the release retry window (~185 ms), so release
        // genuinely throws inside the teardown (fail-closed by design).
        await expectLater(session.close(), throwsA(isA<FileSystemException>()));
      } finally {
        await raf.close();
      }

      // Companion step must still have run: .project.lock is gone even though
      // the session marker release failed.
      expect(
        await package.lockFile.exists(),
        isFalse,
        reason: 'BUG-5: a release failure skipped the companion delete',
      );

      // A later close() must not replay already-completed steps (double
      // dispose) and must complete the deferred marker release.
      await session.close();
      expect(await package.sessionFile.exists(), isFalse);

      final reopened = await ProjectSessionManager().open(package);
      await reopened.close();
    },
    // The blocked-delete precondition is staged with an open file handle:
    // Windows sharing violations block the marker delete, while POSIX
    // unlinks open files so the delete always succeeds there.
    skip: !Platform.isWindows,
  );

  test(
    'BUG-6 a blocked release on the locked-project cleanup path rethrows the '
    'original ProjectLockedException and cleans what it can',
    () async {
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Bug6 open catch');
      final db = await ProjectDatabaseService().open(package.databaseFile.path);
      await ProjectLockService(
        database: db,
        deriver: const Pbkdf2KeyDeriver(),
        integrity: const HmacIntegrity(),
        defaultIterations: 4,
      ).setPassphrase(package.projectId, 's3cret');
      await db.close();

      // Hold a live handle on the COMPANION marker: the open catch deletes it
      // unguarded before the guarded DB close (BUG-6 line 324). The session
      // marker does not exist yet at the throw point, so release() is a no-op
      // and the errno-32 hold must land on the companion delete.
      await package.lockFile.writeAsString('held companion', flush: true);
      final raf = await package.lockFile.open(mode: FileMode.read);
      Object? error;
      try {
        await ProjectSessionManager().open(package);
      } catch (e) {
        error = e;
      } finally {
        await raf.close();
      }

      // The original error must survive the blocked cleanup, not be replaced
      // by the companion-delete failure.
      expect(
        error,
        isA<ProjectLockedException>(),
        reason: 'BUG-6: cleanup failure replaced the original open error',
      );
      expect(
        await package.sessionFile.exists(),
        isFalse,
        reason: 'BUG-6: the session marker must be released on failed open',
      );
    },
    // Same staging constraint as BUG-5: only Windows refuses deleting the
    // file an external handle still has open.
    skip: !Platform.isWindows,
  );

  test('healthy close and healthy failed-open cleanup stay unchanged (guards '
      'must not swallow real failures)', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Healthy path');
    final session = await ProjectSessionManager().open(package);
    await session.close();
    expect(await package.lockFile.exists(), isFalse);
    expect(await package.sessionFile.exists(), isFalse);

    // A mid-open failure (database already open, then the schema reader on
    // a second attempt) must still surface the original error with full
    // cleanup on the healthy path.
    await ProjectDatabaseService().open(package.databaseFile.path);
    final foreign = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Foreign');
    await foreign.sessionFile.writeAsString(
      '{"sessionId":"x","projectId":"${foreign.projectId}",'
      '"processId":$pid,"openedAt":"2026-09-11T00:00:00.000Z"}',
      flush: true,
    );
    await foreign.lockFile.writeAsString('owner marker', flush: true);
    await expectLater(
      ProjectSessionManager().open(foreign),
      throwsA(isA<StateError>()),
    );
    // BUG-18 (run94) contract preserved: the live owner markers survive.
    expect(await foreign.sessionFile.exists(), isTrue);
    expect(await foreign.lockFile.exists(), isTrue);
  });
}
