import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';

void main() {
  test(
    'recover removes every restore staging artifact and returns count',
    () async {
      final root = await Directory.systemTemp.createTemp('restore-crash-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Crash Window');
      // Simulate a killed restore: every area left its staging artifact.
      await File(
        '${package.manifestFile.path}.tmp',
      ).writeAsString('{"partial":true}');
      await File('${package.databaseFile.path}.tmp').writeAsString('torn');
      final assetsTmp = Directory('${package.assetsDirectory.path}.tmp');
      await assetsTmp.create(recursive: true);
      await File('${assetsTmp.path}/portrait.txt').writeAsString('torn');
      final workspacesTmp = Directory(
        '${package.root.path}${Platform.pathSeparator}workspaces.tmp',
      );
      await workspacesTmp.create(recursive: true);
      await File('${workspacesTmp.path}/novel.json').writeAsString('torn');

      final removed = await RestoreCrashRecovery.recover(package);

      expect(removed, 4);
      expect(await File('${package.manifestFile.path}.tmp').exists(), isFalse);
      expect(await File('${package.databaseFile.path}.tmp').exists(), isFalse);
      expect(await assetsTmp.exists(), isFalse);
      expect(await workspacesTmp.exists(), isFalse);
    },
  );

  test('recover on a clean package is a no-op returning zero', () async {
    final root = await Directory.systemTemp.createTemp('restore-clean-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Clean Package');
    expect(await RestoreCrashRecovery.recover(package), 0);
  });

  test('next restore after a crash heals leftover staging artifacts', () async {
    final root = await Directory.systemTemp.createTemp('restore-heal-');
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Heal On Restore');
    final portrait = File('${package.assetsDirectory.path}/portrait.txt');
    await portrait.writeAsString('v1-current');
    final service = ProjectBackupService();
    final backup = await service.create(package: package, type: 'manual');
    await portrait.writeAsString('v2-target');
    // Leftovers from a previous crashed restore.
    await File('${package.manifestFile.path}.tmp').writeAsString('torn');
    final assetsTmp = Directory('${package.assetsDirectory.path}.tmp');
    await assetsTmp.create(recursive: true);

    await service.restore(package: package, backup: backup);

    // Restore proceeded and the payload now matches the backup.
    expect(await portrait.readAsString(), 'v1-current');
    // No staging artifacts survive.
    expect(await File('${package.manifestFile.path}.tmp').exists(), isFalse);
    expect(await assetsTmp.exists(), isFalse);
  });
}
