import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_backup_restore_preview.dart';

void main() {
  late Directory root;
  setUp(
    () async =>
        root = await Directory.systemTemp.createTemp('hermes-s34-preview-'),
  );
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  ProjectPackage makePackage(String id) => ProjectPackage(
    projectId: id,
    root: Directory('${root.path}/$id.voidproject'),
  );

  Future<void> seedManifest(File manifest, String name) async {
    await manifest.create(recursive: true);
    await manifest.writeAsString(jsonEncode({'name': name}));
  }

  Future<void> seedDatabase(File dbFile, int schemaVersion) async {
    await dbFile.parent.create(recursive: true);
    final db = sqlite3.open(dbFile.path);
    db.execute('PRAGMA user_version = $schemaVersion');
    db.close();
  }

  test(
    'preview reports manifest name, db schema, and classified compatibility',
    () async {
      final package = makePackage('p1');
      await seedManifest(package.manifestFile, 'Saga Utama');
      await seedDatabase(
        package.databaseFile,
        ProjectDatabase.currentSchemaVersion,
      );
      final backup = Directory('${package.backupDirectory.path}/b1')
        ..createSync(recursive: true);
      await seedManifest(File('${backup.path}/project.json'), 'Saga Lama');
      await seedDatabase(File('${backup.path}/project.db'), 53);
      final preview = await ProjectBackupRestorePreview.compute(
        package: package,
        backup: backup,
      );
      expect(preview.currentName, 'Saga Utama');
      expect(preview.backupName, 'Saga Lama');
      expect(
        preview.currentSchemaVersion,
        ProjectDatabase.currentSchemaVersion,
      );
      expect(preview.backupSchemaVersion, 53);
      expect(preview.compatibility, RestoreCompatibility.migrationForward);
      expect(preview.warnings, isEmpty);
    },
  );

  test('future schema backup is classified blocked with warning', () async {
    final package = makePackage('p2');
    await seedManifest(package.manifestFile, 'Now');
    await seedDatabase(
      package.databaseFile,
      ProjectDatabase.currentSchemaVersion,
    );
    final backup = Directory('${package.backupDirectory.path}/b2')
      ..createSync(recursive: true);
    await seedManifest(File('${backup.path}/project.json'), 'Future');
    await seedDatabase(File('${backup.path}/project.db'), 99);
    final preview = await ProjectBackupRestorePreview.compute(
      package: package,
      backup: backup,
    );
    expect(preview.compatibility, RestoreCompatibility.blocked);
    expect(preview.warnings, isNotEmpty);
  });

  test(
    'alternate destination restore copies backup without touching live package',
    () async {
      final package = makePackage('p3');
      await seedManifest(package.manifestFile, 'Live');
      await seedDatabase(
        package.databaseFile,
        ProjectDatabase.currentSchemaVersion,
      );
      final backup = Directory('${package.backupDirectory.path}/b3')
        ..createSync(recursive: true);
      await seedManifest(File('${backup.path}/project.json'), 'Restored');
      await seedDatabase(
        File('${backup.path}/project.db'),
        ProjectDatabase.currentSchemaVersion,
      );
      final destRoot = Directory('${root.path}/alt-dest')..createSync();
      final restored =
          await ProjectBackupRestorePreview.restoreToAlternateDestination(
            backup: backup,
            destinationRoot: destRoot,
          );
      expect(restored.projectId, isNotEmpty);
      expect(restored.projectId, isNot(package.projectId));
      expect(restored.manifestFile.existsSync(), isTrue);
      expect(restored.databaseFile.existsSync(), isTrue);
      expect(await restored.manifestFile.readAsString(), contains('Restored'));
      expect(
        await ProjectDatabaseService().schemaVersion(
          restored.databaseFile.path,
        ),
        ProjectDatabase.currentSchemaVersion,
      );
      expect(await package.manifestFile.readAsString(), contains('Live'));
    },
  );
}
