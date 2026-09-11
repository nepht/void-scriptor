import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';

/// BUG-197 run197: the restoreError is the root cause of a failed restore,
/// but BackupRollbackException.toString() never rendered it. When the
/// exception escapes to the global handler, the surface shows only the
/// rollback areas and the emergency-backup path — the actual restore
/// failure is invisible. Referee fix direction: include the restoreError
/// in toString().
void main() {
  test(
    'toString renders the restoreError root cause beside rollback areas',
    () {
      final error = BackupRollbackException(
        emergencyBackupPath: r'C:\tmp\emergency-123',
        restoreError: const FileSystemException('injected manifest lock'),
        rollbackErrors: {'manifest': 'failed', 'database': 'ok'},
      );
      expect(error.toString(), contains('BackupRollbackException'));
      // The root cause must be visible, not only the failing rollback areas.
      expect(
        error.toString(),
        contains('injected manifest lock'),
        reason:
            'BUG-197 run197: restoreError must be rendered so the primary '
            'restore failure is diagnosable from the surfaced message.',
      );
    },
  );

  test(
    'restore that fails rollback surfaces the restoreError in the thrown message',
    () async {
      final root = await Directory.systemTemp.createTemp('rollback-err-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'RollbackRestoreError');
      final portrait = File('${package.assetsDirectory.path}/portrait.txt');
      await portrait.writeAsString('snapshot portrait');

      // The forward restore fails deleting a workspaces tree whose file is
      // held open (Windows sharing, errno 32) — that error is the root
      // cause. The injected manifest rollback failure then produces the
      // BackupRollbackException. Before the fix, toString() rendered only
      // the rollback areas + backup path; the restoreError was invisible
      // (BUG-197 run197 contract).
      final workspace = Directory('${package.root.path}/workspaces');
      await workspace.create(recursive: true);
      final locked = File('${workspace.path}/locked.txt');
      await locked.writeAsString('live locked');
      final lock = await locked.open(mode: FileMode.append);
      addTearDown(lock.close);

      await expectLater(
        _FailingManifestRollbackService().restore(
          package: package,
          backup: await _seedBackup(package, portrait),
        ),
        throwsA(
          isA<BackupRollbackException>()
              .having(
                (error) => error.toString(),
                'message renders root cause',
                allOf(
                  contains('Restore error:'),
                  contains('PathAccessException'),
                ),
              )
              .having(
                (error) => error.toString(),
                'message still names failed area',
                contains('manifest'),
              ),
        ),
      );
    },
    skip: !Platform.isWindows,
  );
}

Future<dynamic> _seedBackup(ProjectPackage package, File portrait) async {
  final service = ProjectBackupService();
  final backup = await service.create(package: package, type: 'manual');
  await portrait.writeAsString('current portrait');
  return backup;
}

class _FailingManifestRollbackService extends ProjectBackupService {
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
