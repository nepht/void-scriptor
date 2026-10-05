import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

/// Sprint 145.42 interrupted-restore crash window: a restore killed between
/// the emergency snapshot and the final area write leaves `'<final>.tmp'`
/// staging artifacts inside the live package. RestoreCrashRecovery.recover
/// documents that "the next session open removes every staging artifact",
/// so opening the project for writing must heal them without requiring the
/// user to attempt another restore. A read-only open must stay read-only
/// and leave the package untouched.
void main() {
  Future<(Directory, dynamic)> seedPackage() async {
    final root = await Directory.systemTemp.createTemp(
      'hermes-s14542-restore-',
    );
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Interrupted Restore');
    return (root, package);
  }

  Future<void> seedStagingArtifacts(dynamic package) async {
    await File('${package.manifestFile.path}.tmp').writeAsString('torn');
    await File('${package.databaseFile.path}.tmp').writeAsString('torn');
    final assetsTmp = Directory('${package.assetsDirectory.path}.tmp');
    await assetsTmp.create(recursive: true);
    await File('${assetsTmp.path}/portrait.txt').writeAsString('torn');
    final workspacesTmp = Directory(
      '${package.root.path}${Platform.pathSeparator}workspaces.tmp',
    );
    await workspacesTmp.create(recursive: true);
    await File('${workspacesTmp.path}/novel.json').writeAsString('torn');
  }

  test(
    'write-mode open heals staging artifacts from an interrupted restore',
    () async {
      final (root, package) = await seedPackage();
      addTearDown(() => root.delete(recursive: true));
      await seedStagingArtifacts(package);

      final manager = ProjectSessionManager();
      final session = await manager.open(package);
      addTearDown(session.close);

      expect(
        await RestoreCrashRecovery.recover(package),
        0,
        reason: 'session open must already have removed every staging artifact',
      );
      expect(await File('${package.manifestFile.path}.tmp').exists(), isFalse);
      expect(await File('${package.databaseFile.path}.tmp').exists(), isFalse);
      expect(
        await Directory('${package.assetsDirectory.path}.tmp').exists(),
        isFalse,
      );
      expect(
        await Directory(
          '${package.root.path}${Platform.pathSeparator}workspaces.tmp',
        ).exists(),
        isFalse,
      );
    },
  );

  test('read-only open never mutates the package staging state', () async {
    final (root, package) = await seedPackage();
    addTearDown(() => root.delete(recursive: true));
    await seedStagingArtifacts(package);

    final manager = ProjectSessionManager();
    final session = await manager.open(package, mode: ProjectOpenMode.readOnly);
    addTearDown(session.close);

    expect(
      await File('${package.manifestFile.path}.tmp').exists(),
      isTrue,
      reason: 'a read-only open must not mutate the package',
    );
    expect(
      await Directory('${package.assetsDirectory.path}.tmp').exists(),
      isTrue,
    );
  });
}
