import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_repository.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_controller.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

void main() {
  test(
    'createBackup enforces manual retention by pruning oldest backup',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'hermes-s34-retention-',
      );
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Ret');
      final session = await ProjectSessionManager().open(package);
      addTearDown(session.close);
      final controller = ProjectResilienceController(
        session,
        retentionPolicy: const BackupRetentionPolicy(
          maxAutomatic: 20,
          maxManual: 2,
        ),
      );

      await controller.createBackup(note: 'first');
      await controller.createBackup(note: 'second');
      await controller.createBackup(note: 'third');

      final rows = await session.database.projectResilienceRepository
          .backupsFor(package.projectId);
      expect(rows, hasLength(2));
      final notes = rows.map((r) => r.note).toSet();
      expect(notes, {'second', 'third'});
      final remaining = package.backupDirectory
          .listSync()
          .whereType<Directory>()
          .length;
      expect(remaining, 2);
    },
  );

  test(
    'default retention policy preserves up to 20 automatic and 50 manual',
    () async {
      final root = await Directory.systemTemp.createTemp('hermes-s34-default-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Def');
      final session = await ProjectSessionManager().open(package);
      addTearDown(session.close);
      final controller = ProjectResilienceController(session);

      for (var i = 0; i < 4; i++) {
        await controller.createBackup(note: 'b$i');
      }
      final rows = await session.database.projectResilienceRepository
          .backupsFor(package.projectId);
      expect(rows, hasLength(4));
      expect(controller.retentionPolicy.maxManual, 50);
    },
  );
}
