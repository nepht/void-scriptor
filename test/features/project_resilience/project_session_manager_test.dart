import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-s24-session-');
  });
  tearDown(() => root.delete(recursive: true));

  test('open acquires lock and close releases it', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Session Project');
    final manager = ProjectSessionManager();

    final session = await manager.open(package);
    expect(session.mode, ProjectOpenMode.readWrite);
    expect(await package.lockFile.exists(), isTrue);

    await manager.close(session);
    expect(await package.lockFile.exists(), isFalse);
    expect(await package.sessionFile.exists(), isFalse);
  });

  test(
    'creates a pre-migration backup before opening an older database',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'hermes-s24-migration-',
      );
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Migration');
      final session = await ProjectSessionManager(
        schemaVersionReader: (_) async => 33,
      ).open(package);
      addTearDown(session.close);
      final backups = await package.backupDirectory
          .list()
          .where((entry) => entry is Directory)
          .toList();
      expect(backups, hasLength(1));
      expect(
        await File('${backups.single.path}/backup.json').readAsString(),
        contains('pre-migration'),
      );
    },
  );

  test('read-only session does not mutate lock or save', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Read Only');
    final manager = ProjectSessionManager();

    final session = await manager.open(package, mode: ProjectOpenMode.readOnly);
    expect(session.mode, ProjectOpenMode.readOnly);
    expect(await package.lockFile.exists(), isFalse);

    await expectLater(session.save(), throwsStateError);
    await expectLater(
      session.database.customStatement(
        "INSERT INTO project_metadata (key, value) VALUES ('forbidden', '1')",
      ),
      throwsA(isA<Object>()),
    );
    await manager.close(session);
  });
}
