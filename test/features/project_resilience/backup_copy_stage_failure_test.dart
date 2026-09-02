import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/backup_location_policy.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_controller.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

void main() {
  test(
    'invalid custom backup root (a file) falls back fail-safe to internal default',
    () async {
      final root = await Directory.systemTemp.createTemp('hermes-s34-cf-root-');
      addTearDown(() => root.delete(recursive: true));
      final badParent = await Directory.systemTemp.createTemp(
        'hermes-s34-cf-bad-',
      );
      addTearDown(() => badParent.delete(recursive: true));
      final badRoot = File('${badParent.path}/drive');
      await badRoot.create();
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Cf');
      final session = await ProjectSessionManager().open(package);
      addTearDown(session.close);
      final controller = ProjectResilienceController(
        session,
        backupLocationPolicy: BackupLocationPolicy(
          customBackupRoot: Directory(badRoot.path),
        ),
      );

      // A file at the custom root path is not a usable directory:
      // the policy must NOT crash and must NOT silently write there;
      // it falls back fail-safe to the package-internal default.
      final backup = await controller.createBackup(note: 'bad-root');
      expect(backup.path.startsWith(package.backupDirectory.path), isTrue);
      final rows = await session.database.projectResilienceRepository
          .backupsFor(package.projectId);
      expect(rows, hasLength(1));
      expect(
        FileSystemEntity.typeSync(badRoot.path),
        FileSystemEntityType.file,
        reason: 'custom root path must remain a file, untouched',
      );
      expect(
        badRoot.lengthSync(),
        0,
        reason: 'nothing was ever written into the invalid root',
      );
    },
  );

  test(
    'restore failure at workspace copy stage rolls back manifest and database from emergency backup',
    () async {
      if (!Platform.isWindows) {
        // File-locking semantics that make delete(recursive:true) fail are
        // Windows-specific; Linux CI skips this injection deterministically.
        return;
      }
      final root = await Directory.systemTemp.createTemp('hermes-s34-rf-root-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Rf');
      final session = await ProjectSessionManager().open(package);
      addTearDown(session.close);

      // Pre-restore live state: workspace file + distinctive manifest name.
      final workspaceDir = Directory('${package.root.path}/workspaces');
      await workspaceDir.create(recursive: true);
      final liveWorkspaceFile = File('${workspaceDir.path}/note.txt');
      await liveWorkspaceFile.writeAsString('live workspace content');

      // Create a valid backup capturing the original manifest name.
      final backup = await ProjectBackupService().create(
        package: package,
        type: 'manual',
        note: 'pre-restore',
      );

      // Mutate live manifest to a NEW name; the backup still holds the old one.
      final manifest = package.manifestFile;
      final before = manifest.readAsStringSync();
      manifest.writeAsStringSync(
        before.replaceFirst('"name": "Rf"', '"name": "Rf-changed"'),
      );

      // Hold an exclusive handle on the live workspace file so the restore's
      // workspace delete stage fails deterministically (Windows sharing).
      final lock = await liveWorkspaceFile.open(mode: FileMode.append);
      addTearDown(() async => lock.close());

      await expectLater(
        ProjectBackupService().restore(package: package, backup: backup),
        throwsA(anything),
      );

      // Rollback: manifest restored to the emergency (pre-restore) content.
      expect(
        manifest.readAsStringSync().contains('"name": "Rf-changed"'),
        isTrue,
        reason:
            'failed restore must leave the live project at its '
            'pre-restore state, not the backup snapshot',
      );
      expect(liveWorkspaceFile.existsSync(), isTrue);
      expect(liveWorkspaceFile.readAsStringSync(), 'live workspace content');
    },
  );
}
