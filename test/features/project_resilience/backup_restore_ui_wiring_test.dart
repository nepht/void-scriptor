import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/project_resilience/application/project_backup_restore_flow.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_controller.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

/// GAP-BACKUP-RESTORE-NO-UI (run228 finding): ProjectBackupService.restore()
/// was domain+test only. This file pins the wiring contracts that make a
/// backup restorable from the Project Backups screen:
///   1. ProjectResilienceController.restoreBackup writes the recorded
///      snapshot over the live package files (exact snapshot semantics).
///   2. Read-only sessions are rejected fail-closed.
///   3. ProjectBackupRestoreFlow closes the active session before the
///      overwrite and reopens the same project afterwards, so the shell
///      never holds a session whose database file was replaced mid-flight.
void main() {
  Future<ProjectPackage> makePackage(Directory root, String name) =>
      ProjectPackageService(rootDirectory: root).create(name: name);

  Future<void> mutateLiveState(ProjectPackage package) async {
    final manifest =
        jsonDecode(await package.manifestFile.readAsString())
            as Map<String, dynamic>;
    manifest['name'] = 'Mutated After Backup';
    await package.manifestFile.writeAsString(jsonEncode(manifest));
    final marker = File(
      p.join(package.assetsDirectory.path, 'marker-created-after-backup.txt'),
    );
    await marker.parent.create(recursive: true);
    await marker.writeAsString('leftover live state');
  }

  Future<List<ProjectBackup>> rowsFor(ProjectSession session, String id) =>
      session.database.projectResilienceRepository.backupsFor(id);

  test(
    'restoreBackup writes the recorded snapshot over the live package files',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'hermes-restorewire-ctrl-',
      );
      addTearDown(() => root.delete(recursive: true));
      final package = await makePackage(root, 'Restore UI Wire');
      final session = await ProjectSessionManager().open(package);
      final controller = ProjectResilienceController(session);
      await controller.createBackup(note: 'ui-wire-slice');
      final rows = await rowsFor(session, package.projectId);
      expect(rows, hasLength(1));
      await session.close();

      await mutateLiveState(package);
      expect(
        (jsonDecode(await package.manifestFile.readAsString())
            as Map<String, dynamic>)['name'],
        'Mutated After Backup',
      );

      await controller.restoreBackup(rows.single);

      final restoredName =
          (jsonDecode(await package.manifestFile.readAsString())
              as Map<String, dynamic>)['name'];
      expect(restoredName, 'Restore UI Wire');
      expect(
        File(
          p.join(
            package.assetsDirectory.path,
            'marker-created-after-backup.txt',
          ),
        ).existsSync(),
        isFalse,
        reason: 'restore is an exact snapshot switch, not a merge',
      );
      final backupDirs = package.backupDirectory
          .listSync()
          .whereType<Directory>()
          .length;
      expect(
        backupDirs,
        greaterThanOrEqualTo(2),
        reason: 'the pre-restore emergency backup must be retained on disk',
      );

      // The restored manifest/database pair must be a valid project again.
      final reopened = await ProjectSessionManager().open(package);
      addTearDown(reopened.close);
      final check = await reopened.database
          .customSelect('PRAGMA quick_check')
          .getSingle();
      expect(check.data.values.first, 'ok');
    },
  );

  test('restoreBackup rejects read-only sessions fail-closed', () async {
    final root = await Directory.systemTemp.createTemp(
      'hermes-restorewire-ro-',
    );
    addTearDown(() => root.delete(recursive: true));
    final package = await makePackage(root, 'Restore Read Only');
    final writer = await ProjectSessionManager().open(package);
    final writeController = ProjectResilienceController(writer);
    await writeController.createBackup(note: 'ro-seed');
    final rows = await rowsFor(writer, package.projectId);
    await writer.close();

    final readOnly = await ProjectSessionManager().open(
      package,
      mode: ProjectOpenMode.readOnly,
    );
    addTearDown(readOnly.close);
    await expectLater(
      ProjectResilienceController(readOnly).restoreBackup(rows.single),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'restoreBackupAndReopen closes, restores, and reopens the same project',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'hermes-restorewire-flow-',
      );
      final container = ProviderContainer(
        overrides: [
          projectPathsProvider.overrideWithValue(
            ProjectPaths(rootDirectory: root),
          ),
        ],
      );
      try {
        final package = await makePackage(root, 'Flow Wire');
        final controller = container.read(projectSessionProvider.notifier);
        await controller.open(package.projectId);
        final session =
            container.read(projectSessionProvider).valueOrNull!;
        await ProjectResilienceController(
          session,
        ).createBackup(note: 'flow-slice');
        final rows = await rowsFor(session, package.projectId);
        expect(rows, hasLength(1));

        await mutateLiveState(package);

        await ProjectBackupRestoreFlow.restoreBackupAndReopen(
          closeActiveSession: controller.closeProject,
          reopenProject: () => controller.open(package.projectId),
          session: session,
          backup: rows.single,
        );

        final fresh = container.read(projectSessionProvider).valueOrNull;
        expect(fresh, isNotNull, reason: 'the project must reopen after restore');
        expect(fresh!.package.projectId, package.projectId);
        expect(identical(fresh, session), isFalse);
        expect(fresh.manifest.name, 'Flow Wire');
        expect(
          File(
            p.join(
              package.assetsDirectory.path,
              'marker-created-after-backup.txt',
            ),
          ).existsSync(),
          isFalse,
        );
        final check = await fresh.database
            .customSelect('PRAGMA quick_check')
            .getSingle();
        expect(check.data.values.first, 'ok');
      } finally {
        await container.read(projectSessionProvider.notifier).closeProject();
        container.dispose();
        if (await root.exists()) await root.delete(recursive: true);
      }
    },
  );

  test(
    'restoreBackupAndReopen aborts fail-closed when the backup schema is '
    'newer than the application schema',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'hermes-restorewire-block-',
      );
      addTearDown(() => root.delete(recursive: true));
      final package = await makePackage(root, 'Blocked Future Schema');
      final session = await ProjectSessionManager().open(package);
      final controller = ProjectResilienceController(session);
      await controller.createBackup(note: 'future-schema');
      final rows = await rowsFor(session, package.projectId);

      // Rewrite the recorded snapshot's database to a future user_version so
      // the compatibility preview classifies it blocked. The controller row
      // still references the backup directory on disk.
      final dbPath = p.join(
        package.backupDirectory.path,
        rows.single.id,
        'project.db',
      );
      final raw = sqlite3.open(dbPath);
      raw.execute(
        'PRAGMA user_version = ${ProjectDatabase.currentSchemaVersion + 7}',
      );
      raw.close();
      await session.close();

      var reopenAttempts = 0;
      await expectLater(
        ProjectBackupRestoreFlow.restoreBackupAndReopen(
          closeActiveSession: () async {},
          reopenProject: () async => reopenAttempts++,
          session: session,
          backup: rows.single,
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        reopenAttempts,
        0,
        reason:
            'a blocked restore must never proceed to reopen; the shell stays '
            'on the live session',
      );
    },
  );
}
