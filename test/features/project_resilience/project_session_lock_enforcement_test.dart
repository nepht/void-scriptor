import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/application/project_lock_service.dart';
import 'package:void_scriptor/core/security/crypto/encryption_cipher.dart';
import 'package:void_scriptor/core/security/crypto/key_derivation.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

void main() {
  late Directory root;
  late ProjectPackage package;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('core-hunt-20260906-lock-');
    package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Locked Project');
  });

  tearDown(() async {
    try {
      await root.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  /// Seeds the passphrase lock directly in the package database, the way
  /// the lock UI would (fast PBKDF2 via the injected iteration count).
  Future<void> seedLock(String passphrase, {required bool locked}) async {
    final db = await ProjectDatabaseService().open(package.databaseFile.path);
    final service = ProjectLockService(
      database: db,
      deriver: const Pbkdf2KeyDeriver(),
      integrity: const HmacIntegrity(),
      defaultIterations: 4,
    );
    if (passphrase.isNotEmpty) {
      await service.setPassphrase(package.projectId, passphrase);
    }
    if (!locked) {
      await service.unlock(package.projectId, passphrase);
    }
    await db.close();
  }

  group('core-hunt-20260906 session open lock enforcement (BUG-21)', () {
    test('open throws ProjectLockedException for a locked project and leaves '
        'no session lock file behind', () async {
      await seedLock('s3cret', locked: true);

      await expectLater(
        ProjectSessionManager().open(package),
        throwsA(isA<ProjectLockedException>()),
      );

      // The failed open must not leave the write-companion behind.
      expect(await package.lockFile.exists(), isFalse);
    });

    test('open succeeds after the passphrase is unlocked', () async {
      await seedLock('s3cret', locked: false);

      final session = await ProjectSessionManager().open(package);
      await session.close();

      expect(session.manifest.id, package.projectId);
    });

    test('an unlocked project without any lock row opens normally', () async {
      final session = await ProjectSessionManager().open(package);
      await session.close();

      expect(session.manifest.id, package.projectId);
    });
  });
}
