import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';

/// Injection harness: the production rollback restores all four payload areas
/// from the emergency backup. This subclass fails ONLY the manifest area so
/// the remaining areas execute for real.
class FailingManifestRollbackService extends ProjectBackupService {
  @override
  Future<Map<String, Object>> rollbackPayloadAreas(
    ProjectPackage package,
    Directory emergency, {
    Future<void> Function()? manifest,
    Future<void> Function()? database,
    Future<void> Function()? assets,
    Future<void> Function()? workspaces,
  }) {
    return super.rollbackPayloadAreas(
      package,
      emergency,
      manifest: () =>
          Future.error(const FileSystemException('injected manifest lock')),
      database: database,
      assets: assets,
      workspaces: workspaces,
    );
  }
}

/// Injection harness failing every rollback area to prove failure aggregation.
class AllAreasFailingRollbackService extends ProjectBackupService {
  @override
  Future<Map<String, Object>> rollbackPayloadAreas(
    ProjectPackage package,
    Directory emergency, {
    Future<void> Function()? manifest,
    Future<void> Function()? database,
    Future<void> Function()? assets,
    Future<void> Function()? workspaces,
  }) {
    Future<void> fail() =>
        Future.error(const FileSystemException('injected rollback failure'));
    return super.rollbackPayloadAreas(
      package,
      emergency,
      manifest: fail,
      database: database == null ? null : fail,
      assets: assets == null ? null : fail,
      workspaces: workspaces == null ? null : fail,
    );
  }
}

void main() {
  test(
    'failed rollback reports failing area, restores remaining areas, keeps emergency backup',
    () async {
      final root = await Directory.systemTemp.createTemp('rollback-fail-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'RollbackFail');
      final portrait = File('${package.assetsDirectory.path}/portrait.txt');
      final workspace = Directory('${package.root.path}/workspaces');
      await workspace.create(recursive: true);
      final note = File('${workspace.path}/note.txt');
      final untouched = File('${workspace.path}/untouched.txt');
      await portrait.writeAsString('snapshot portrait');
      await note.writeAsString('snapshot note');
      await untouched.writeAsString('untouched');
      final service = ProjectBackupService();
      final backup = await service.create(package: package, type: 'manual');

      await portrait.writeAsString('current portrait');
      await note.writeAsString('current note');

      // Hold an exclusive handle on a workspace file whose content matches the
      // emergency snapshot: the forward restore fails deleting it (Windows
      // sharing), while the rollback skips it as hash-identical, so only the
      // injected manifest rollback failure remains.
      final lock = await untouched.open(mode: FileMode.append);
      addTearDown(lock.close);

      await expectLater(
        FailingManifestRollbackService().restore(
          package: package,
          backup: backup,
        ),
        throwsA(
          isA<BackupRollbackException>()
              .having((error) => error.rollbackErrors.keys, 'rollbackErrors', [
                'manifest',
              ])
              .having(
                (error) => error.toString(),
                'message',
                contains('manifest'),
              ),
        ),
      );

      // Rollback restores the emergency (pre-restore) state, not the older
      // backup being restored. Failed restore must preserve current edits.
      expect(await portrait.readAsString(), 'current portrait');
      expect(await note.readAsString(), 'current note');

      // The emergency backup is retained for the user.
      final emergencyDirs = package.backupDirectory
          .listSync()
          .whereType<Directory>()
          .where((entry) => entry.path != backup.path)
          .toList();
      expect(emergencyDirs, hasLength(1));
      final emergencyDir = emergencyDirs.single;
      expect(File('${emergencyDir.path}/project.json').existsSync(), isTrue);
      expect(File('${emergencyDir.path}/project.db').existsSync(), isTrue);
    },
    skip: !Platform.isWindows,
  );

  test(
    'rollback failure in every area is aggregated and the emergency backup is retained',
    () async {
      final root = await Directory.systemTemp.createTemp('rollback-all-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'RollbackAllFail');
      final portrait = File('${package.assetsDirectory.path}/portrait.txt');
      await portrait.writeAsString('snapshot portrait');
      final service = AllAreasFailingRollbackService();
      final backup = await service.create(package: package, type: 'manual');
      await portrait.writeAsString('current portrait');

      // A locked live workspace file makes the forward restore fail so the
      // all-areas rollback injection is exercised.
      final workspace = Directory('${package.root.path}/workspaces');
      await workspace.create(recursive: true);
      final locked = File('${workspace.path}/locked.txt');
      await locked.writeAsString('live locked');
      final lock = await locked.open(mode: FileMode.append);
      addTearDown(lock.close);

      await expectLater(
        service.restoreWithRollback(package: package, backup: backup),
        throwsA(
          isA<BackupRollbackException>()
              .having(
                (error) => error.rollbackErrors.keys.toSet(),
                'rollbackErrors',
                {'manifest', 'database', 'assets', 'workspaces'},
              )
              .having(
                (error) => error.emergencyBackupPath,
                'emergencyBackupPath',
                isNotEmpty,
              ),
        ),
      );
      // Emergency backup retained even when every rollback area failed.
      final emergency = Directory(service.lastEmergencyBackupPath!);
      expect(emergency.existsSync(), isTrue);
      expect(File('${emergency.path}/project.json').existsSync(), isTrue);
    },
    // Forward restore must fail so every rollback area is exercised: the
    // trigger is a live workspace file held open (Windows sharing
    // violation). POSIX unlinks open files, so it only stages on Windows.
    skip: !Platform.isWindows,
  );
}
