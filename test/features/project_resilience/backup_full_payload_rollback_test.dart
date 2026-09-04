import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';

Future<Map<String, List<int>>> payload(Directory root) async => {
  await for (final entry in root.list(recursive: true, followLinks: false))
    if (entry is File)
      entry.path.substring(root.path.length): await entry.readAsBytes(),
};

void main() {
  test(
    'failed restore rolls back changed and introduced assets and workspace files',
    () async {
      final root = await Directory.systemTemp.createTemp('restore-payload-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Restore rollback');
      final portrait = File('${package.assetsDirectory.path}/portrait.txt');
      final obsolete = File('${package.assetsDirectory.path}/old.txt');
      final workspace = Directory('${package.root.path}/workspaces');
      await workspace.create(recursive: true);
      final locked = File('${workspace.path}/locked.txt');
      await portrait.writeAsString('snapshot portrait');
      await obsolete.writeAsString('snapshot-only');
      await locked.writeAsString('snapshot workspace');
      final service = ProjectBackupService();
      final backup = await service.create(package: package, type: 'manual');
      await portrait.writeAsString('current portrait');
      await obsolete.delete();
      await File(
        '${package.assetsDirectory.path}/live-only.txt',
      ).writeAsString('keep');
      await locked.writeAsString('current workspace');
      await File('${workspace.path}/other.txt').writeAsString('current other');
      final assetsBefore = await payload(package.assetsDirectory);
      final workspaceBefore = await payload(workspace);
      final manifestBefore = await package.manifestFile.readAsBytes();
      final databaseBefore = await package.databaseFile.readAsBytes();
      final handle = await locked.open(mode: FileMode.append);
      addTearDown(handle.close);

      await expectLater(
        service.restore(package: package, backup: backup),
        throwsA(isA<FileSystemException>()),
      );

      expect(await payload(package.assetsDirectory), assetsBefore);
      expect(await payload(workspace), workspaceBefore);
      expect(await package.manifestFile.readAsBytes(), manifestBefore);
      expect(await package.databaseFile.readAsBytes(), databaseBefore);
    },
    skip: !Platform.isWindows,
  );

  test(
    'emergency backup failure aborts before changing the live payload',
    () async {
      final root = await Directory.systemTemp.createTemp('restore-emergency-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Emergency guard');
      final portrait = File('${package.assetsDirectory.path}/portrait.txt');
      await portrait.writeAsString('snapshot');
      final service = ProjectBackupService();
      final backup = await service.create(
        package: package,
        type: 'manual',
        destinationRoot: Directory('${root.path}/external-backups'),
      );
      await portrait.writeAsString('current');
      // The package has no internal backup yet. A file prevents directory creation.
      await package.backupDirectory.delete(recursive: true);
      await File(package.backupDirectory.path).writeAsString('blocked');
      final before = await payload(package.root);
      await expectLater(
        service.restore(package: package, backup: backup),
        throwsA(isA<FileSystemException>()),
      );
      expect(await payload(package.root), before);
    },
  );
}
