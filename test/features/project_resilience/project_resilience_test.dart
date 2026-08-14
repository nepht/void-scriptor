import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_repository.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';

void main() {
  late Directory temp;
  late ProjectPackage package;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('hermes-s24-files-');
    package = ProjectPackage(projectId: 'p-1', root: temp);
    await package.root.create(recursive: true);
    await Directory('${temp.path}/assets/audio').create(recursive: true);
    await File('${temp.path}/assets/audio/a.wav').writeAsString('audio');
  });
  tearDown(() => temp.delete(recursive: true));

  test(
    'resolves internal, external, and missing references and converts paths',
    () async {
      final service = ProjectFileReferenceService(package);
      final internal = service.resolve('assets/audio/a.wav');
      expect(internal.location, ProjectFileLocation.internal);
      expect(
        service.toRelative('${temp.path}/assets/audio/a.wav'),
        'assets/audio/a.wav',
      );
      expect(
        service.resolve('${temp.path}/outside.wav').location,
        ProjectFileLocation.missing,
      );
      expect(
        service.resolve('assets/audio/missing.wav').location,
        ProjectFileLocation.missing,
      );
      expect(
        await service.hash(File('${temp.path}/assets/audio/a.wav')),
        hasLength(64),
      );
    },
  );

  test('resilience metadata persists after database restart', () async {
    final dbFile = File('${temp.path}/database/project.db')
      ..parent.createSync(recursive: true);
    final service = ProjectDatabaseService();
    final db = await service.open(dbFile.path);
    await db.projectResilienceRepository.addExternal(
      ExternalFilesCompanion.insert(
        id: 'e-1',
        projectId: 'p-1',
        absolutePath: '/outside/a.wav',
      ),
    );
    await db.projectResilienceRepository.addBackup(
      ProjectBackupsCompanion.insert(
        id: 'b-1',
        projectId: 'p-1',
        type: 'manual',
        relativePath: 'backups/b-1',
        schemaVersion: 34,
        sizeBytes: 10,
        createdAt: DateTime(2026),
      ),
    );
    await db.close();
    final reopened = await service.open(dbFile.path);
    addTearDown(reopened.close);
    expect(
      (await reopened.projectResilienceRepository.externalFor('p-1')).single.id,
      'e-1',
    );
    expect(
      (await reopened.projectResilienceRepository.backupsFor(
        'p-1',
      )).single.type,
      'manual',
    );
  });
}
