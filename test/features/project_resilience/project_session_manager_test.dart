import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/security/application/project_lock_service.dart';
import 'package:void_scriptor/core/security/crypto/encryption_cipher.dart';
import 'package:void_scriptor/core/security/crypto/key_derivation.dart';
import 'package:void_scriptor/features/character/application/rename_character_command.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
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
    await session.versionControl.createSnapshot(
      label: 'Session Revision',
      assetType: 'project',
      assetId: package.projectId,
      data: const {'state': 'open'},
    );
    expect(await session.versionControl.listSnapshots(), hasLength(1));

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

  test('reopens persistent character command history', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'History Project');
    final manager = ProjectSessionManager();
    final session = await manager.open(package);
    final repository = CharacterRepositoryImpl(
      database: session.database,
      projectId: package.projectId,
      paths: ProjectPaths(rootDirectory: root),
    );
    final character = await repository.createCharacter(name: 'Qowner');
    await session.mutationRuntime.bus.execute(
      RenameCharacterCommand(
        id: 'session-rename-1',
        projectId: package.projectId,
        repository: repository,
        characterId: character.assetId,
        oldName: 'Qowner',
        newName: 'Nephthys',
      ),
    );
    await manager.close(session);

    final reopened = await manager.open(package);
    addTearDown(() => manager.close(reopened));
    expect(reopened.mutationRuntime.bus.canUndo, isTrue);
    await reopened.mutationRuntime.bus.undo();
    final reopenedRepository = CharacterRepositoryImpl(
      database: reopened.database,
      projectId: package.projectId,
      paths: ProjectPaths(rootDirectory: root),
    );
    expect(
      (await reopenedRepository.getCharacter(character.assetId))!.displayName,
      'Qowner',
    );
  });

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

  test('bug-hunt vs-hunt-20260911 BUG-1: unlockProject creates the '
      'pre-migration backup before migrating an older database', () async {
    final root = await Directory.systemTemp.createTemp(
      'hermes-unlock-migration-',
    );
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Unlock Migration');
    final manager = ProjectSessionManager(schemaVersionReader: (_) async => 33);
    final setup = await manager.open(package);
    final lockService = ProjectLockService(
      database: setup.database,
      deriver: const Pbkdf2KeyDeriver(),
      integrity: const HmacIntegrity(),
    );
    await lockService.setPassphrase(package.projectId, 'correct horse');
    await setup.close();

    // The open() guarded path already created one pre-migration backup at
    // session setup; the unlock probe on the same old-schema database must
    // not skip the guard that open() applies to every other writer.
    final unlocked = await manager.unlockProject(package, 'correct horse');
    expect(unlocked, isTrue);

    final backups = await package.backupDirectory
        .list()
        .where((entry) => entry is Directory)
        .toList();
    expect(backups.length, greaterThanOrEqualTo(2));
  }, skip: !Platform.isWindows);
}
