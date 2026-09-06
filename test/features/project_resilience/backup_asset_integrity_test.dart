import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';

void main() {
  for (final change in ['tampered', 'missing', 'extra']) {
    test(
      'restore rejects $change backup assets before touching live data',
      () async {
        final root = await Directory.systemTemp.createTemp('backup-assets-');
        addTearDown(() => root.delete(recursive: true));
        final package = await ProjectPackageService(
          rootDirectory: root,
        ).create(name: 'Asset integrity');
        final live = File('${package.assetsDirectory.path}/portrait.txt');
        await live.writeAsString('snapshot');
        final service = ProjectBackupService();
        final backup = await service.create(package: package, type: 'manual');
        await live.writeAsString('live version');
        final manifestBefore = await package.manifestFile.readAsBytes();
        final databaseBefore = await package.databaseFile.readAsBytes();
        final backupAsset = File('${backup.path}/assets/portrait.txt');
        if (change == 'tampered') await backupAsset.writeAsString('corrupt');
        if (change == 'missing') await backupAsset.delete();
        if (change == 'extra') {
          await File(
            '${backup.path}/assets/unexpected.txt',
          ).writeAsString('extra');
        }
        await expectLater(
          service.restore(package: package, backup: backup),
          throwsA(isA<BackupIntegrityException>()),
        );
        expect(await live.readAsString(), 'live version');
        expect(await package.manifestFile.readAsBytes(), manifestBefore);
        expect(await package.databaseFile.readAsBytes(), databaseBefore);
        expect(
          await package.backupDirectory.list().length,
          1,
          reason:
              'reject before creating emergency backup or mutating live data',
        );
      },
    );
  }
}
