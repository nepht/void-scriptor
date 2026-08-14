import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_controller.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

void main() {
  test(
    'controller scans and executes backup export cache and orphan repair',
    () async {
      final root = await Directory.systemTemp.createTemp('hermes-s24-live-ui-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Live');
      final orphan = File(package.resolve('assets/images/orphan.png'));
      await orphan.writeAsBytes([1, 2, 3]);
      final cache = File('${package.cacheDirectory.path}/preview.tmp');
      await cache.parent.create(recursive: true);
      await cache.writeAsString('cache');
      final session = await ProjectSessionManager().open(package);
      addTearDown(session.close);
      final controller = ProjectResilienceController(session);

      final initial = await controller.scan();
      expect(initial.integrity.orphanFiles, 1);
      expect(initial.storage.totalBytes, greaterThan(0));

      final backup = await controller.createBackup(note: 'Manual verification');
      expect(await File('${backup.path}/backup.json').exists(), isTrue);
      final archive = await controller.exportPortable();
      expect(await archive.exists(), isTrue);
      await controller.clearCache();
      expect(await cache.exists(), isFalse);
      final repaired = await controller.moveOrphansToTrash();
      expect(repaired, 1);
      expect(await orphan.exists(), isFalse);
      expect((await controller.scan()).trashItems, 1);
    },
  );
}
