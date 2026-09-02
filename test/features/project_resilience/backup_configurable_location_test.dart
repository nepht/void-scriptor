import 'dart:io';

export 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/backup_location_policy.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_controller.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_repository.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

String p_join(String path) => path.replaceAll('/', Platform.pathSeparator);

void main() {
  test(
    'createBackup with custom backup location writes snapshot to custom root',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'hermes-s34-conf-root-',
      );
      addTearDown(() => root.delete(recursive: true));
      final customRoot = await Directory.systemTemp.createTemp(
        'hermes-s34-conf-custom-',
      );
      addTearDown(() => customRoot.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Conf');
      final session = await ProjectSessionManager().open(package);
      addTearDown(session.close);
      final controller = ProjectResilienceController(
        session,
        backupLocationPolicy: BackupLocationPolicy(),
      );
      controller.configureCustomBackupRoot(customRoot);

      final backup = await controller.createBackup(note: 'custom-loc');

      expect(backup.path.startsWith(customRoot.path), isTrue);
      expect(customRoot.listSync().whereType<Directory>().length, 1);
      // The internal backups dir exists from package creation, but no
      // backup snapshot was written into it.
      expect(
        Directory(
          package.backupDirectory.path,
        ).listSync().whereType<Directory>(),
        isEmpty,
      );
      final row =
          (await session.database.projectResilienceRepository.backupsFor(
            package.projectId,
          )).single;
      expect(row.relativePath, backup.path);
      expect(Directory(row.relativePath).existsSync(), isTrue);
      expect(File('${row.relativePath}/backup.json').existsSync(), isTrue);
    },
  );

  test(
    'missing custom location falls back fail-safe to internal default and retention spans both',
    () async {
      final root = await Directory.systemTemp.createTemp('hermes-s34-fs-root-');
      addTearDown(() => root.delete(recursive: true));
      final customRoot = await Directory.systemTemp.createTemp(
        'hermes-s34-fs-custom-',
      );
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Fs');
      final session = await ProjectSessionManager().open(package);
      addTearDown(session.close);
      final controller = ProjectResilienceController(
        session,
        backupLocationPolicy: BackupLocationPolicy(),
        retentionPolicy: const BackupRetentionPolicy(maxManual: 1),
      );
      controller.configureCustomBackupRoot(customRoot);

      final first = await controller.createBackup(note: 'first');
      expect(first.path.startsWith(customRoot.path), isTrue);

      // Simulate removal/relink: custom drive content disappears.
      customRoot.deleteSync(recursive: true);

      // Fail-safe: next backup lands in the internal default location.
      final second = await controller.createBackup(note: 'second');
      expect(second.path.startsWith(package.backupDirectory.path), isTrue);

      // Retention (maxManual=1) prunes the OLDEST across both locations.
      await controller.createBackup(note: 'third');
      final rows = await session.database.projectResilienceRepository
          .backupsFor(package.projectId);
      expect(rows.map((r) => r.note), ['third']);
      // Custom root was deleted simulating drive removal; the pruned
      // oldest custom backup row is gone without any crash or stale row.
      expect(customRoot.existsSync(), isFalse);
      expect(
        package.backupDirectory.listSync().whereType<Directory>().length,
        1,
      );
    },
  );
}
