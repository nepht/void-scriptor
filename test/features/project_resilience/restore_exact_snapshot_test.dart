import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';

/// Sprint 145.42 - Data Safety Failure Matrix: exact-snapshot restore.
///
/// A successful backup restore must reproduce the backed-up payload EXACTLY.
/// Assets are the one area where the previous restore merged the backup
/// into the live directory: files created after the backup survived a
/// "restore", so a user rolling back to a known-good snapshot silently
/// kept newer unknown files. A restore is a snapshot switch, not a merge.
void main() {
  test(
    'successful restore replaces the assets directory with the backup '
    'contents (files created after the backup do not survive)',
    () async {
      final root = await Directory.systemTemp.createTemp('restore-exact-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Exact Snapshot');
      final service = ProjectBackupService();

      final kept = File('${package.assetsDirectory.path}/kept.txt');
      await kept.writeAsString('kept-from-backup');
      final backup = await service.create(package: package, type: 'manual');

      // Live-only state that exists AFTER the snapshot was taken: a new
      // asset file and a new asset subdirectory tree.
      final stray = File('${package.assetsDirectory.path}/stray-newer.txt');
      await stray.writeAsString('created-after-backup');
      final strayDir = Directory(
        '${package.assetsDirectory.path}/new-sub',
      );
      await strayDir.create(recursive: true);
      await File('${strayDir.path}/nested.txt').writeAsString('nested-new');

      await service.restore(package: package, backup: backup);

      // Snapshot content is restored...
      expect(await kept.readAsString(), 'kept-from-backup');
      // ...and post-backup live-only files are GONE: restore is exact.
      expect(
        await stray.exists(),
        isFalse,
        reason:
            'a file created after the backup must not survive a restore; '
            'a restore is a snapshot switch, not a merge',
      );
      expect(
        await strayDir.exists(),
        isFalse,
        reason: 'post-backup asset subdirectories must not survive a restore',
      );
    },
  );

  test(
    'a failed restore still returns the live project to its pre-restore '
    'state including post-backup live-only files (rollback stays exact)',
    () async {
      final root = await Directory.systemTemp.createTemp('restore-rollback-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Exact Rollback');
      final service = ProjectBackupService();

      final kept = File('${package.assetsDirectory.path}/kept.txt');
      await kept.writeAsString('kept-from-backup');
      final backup = await service.create(package: package, type: 'manual');

      final stray = File('${package.assetsDirectory.path}/stray-newer.txt');
      await stray.writeAsString('created-after-backup');

      // Sabotage the backup manifest checksum so restore fails after the
      // pre-restore emergency snapshot was taken.
      final backupManifest = File('${backup.path}/project.json');
      await backupManifest.writeAsString('{"broken": true}');

      await expectLater(
        service.restore(package: package, backup: backup),
        throwsA(isA<BackupIntegrityException>()),
      );

      // Live project untouched: the stray file must still exist because
      // this failure happened BEFORE any live mutation.
      expect(await stray.exists(), isTrue);
      expect(await kept.readAsString(), 'kept-from-backup');
    },
  );
}
