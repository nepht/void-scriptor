import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/character_mode/application/create_character_mode_service.dart';
import 'package:void_scriptor/features/character_mode/data/character_loadout_repository_impl.dart';
import 'package:void_scriptor/features/character_mode/data/character_mode_repository_impl.dart';
import 'package:void_scriptor/features/character_mode/data/character_mode_reference_repository.dart';
import 'package:void_scriptor/features/character_mode/domain/loadout_slot.dart';

void main() {
  late Directory tempDir;
  late ProjectDatabase database;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('character-mode-test-');
    final paths = ProjectPaths(rootDirectory: tempDir);
    await ProjectDatabaseService().create(
      (await paths.database('project-1')).path,
    );
    database = await ProjectDatabaseService().open(
      (await paths.database('project-1')).path,
    );
    await database
        .into(database.assets)
        .insert(
          AssetsCompanion.insert(
            id: 'character-1',
            projectId: 'project-1',
            name: 'Qowner',
            type: 'character',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        );
  });

  tearDown(() async {
    await database.close();
    await tempDir.delete(recursive: true);
  });

  test('create mode seeds override and keeps one default', () async {
    final service = CreateCharacterModeService(database: database);

    final baseId = await service.create(
      projectId: 'project-1',
      characterId: 'character-1',
      name: 'Base Mode',
      isDefault: true,
    );
    final combatId = await service.create(
      projectId: 'project-1',
      characterId: 'character-1',
      name: 'Combat Mode',
      isDefault: true,
    );

    final modes = await database.characterModeDao.getModes('character-1');
    expect(modes, hasLength(2));
    expect(modes.singleWhere((mode) => mode.id == combatId).isDefault, isTrue);
    expect(modes.singleWhere((mode) => mode.id == baseId).isDefault, isFalse);
    expect(
      await database.characterModeDao.getIdentityOverride(combatId),
      isNotNull,
    );
  });

  test('loadout repository validates asset type and single slot', () async {
    await database
        .into(database.characterModes)
        .insert(
          CharacterModesCompanion.insert(
            id: 'mode-1',
            projectId: 'project-1',
            characterId: 'character-1',
            name: 'Combat Mode',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        );
    await database
        .into(database.assets)
        .insert(
          AssetsCompanion.insert(
            id: 'weapon-1',
            projectId: 'project-1',
            name: 'Void Dagger',
            type: 'weapon',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        );

    final repository = CharacterLoadoutRepositoryImpl(database);
    await repository.setSlot(
      modeId: 'mode-1',
      slot: LoadoutSlot.primaryWeapon,
      assetId: 'weapon-1',
    );

    expect(await repository.getLoadout('mode-1'), hasLength(1));
    final relations = await database.select(database.assetRelations).get();
    expect(relations, hasLength(1));
    expect(relations.single.relationType, 'uses');
    expectLater(
      repository.setSlot(
        modeId: 'mode-1',
        slot: LoadoutSlot.primaryWeapon,
        assetId: 'character-1',
      ),
      throwsArgumentError,
    );
  });

  test(
    'clone mode copies loadout and identity override with fresh ids',
    () async {
      final modeRepository = CharacterModeRepositoryImpl(database);
      final sourceId = await modeRepository.createMode(
        projectId: 'project-1',
        characterId: 'character-1',
        name: 'Daily Mode',
        isDefault: true,
      );
      await database
          .into(database.assets)
          .insert(
            AssetsCompanion.insert(
              id: 'weapon-2',
              projectId: 'project-1',
              name: 'Void Sword',
              type: 'weapon',
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
            ),
          );
      final loadout = CharacterLoadoutRepositoryImpl(database);
      await loadout.setSlot(
        modeId: sourceId,
        slot: LoadoutSlot.primaryWeapon,
        assetId: 'weapon-2',
      );

      final clonedId = await modeRepository.cloneMode(
        sourceModeId: sourceId,
        name: 'Combat Mode',
      );
      expect(clonedId, isNot(sourceId));
      expect(await loadout.getLoadout(clonedId), hasLength(1));
      expect(
        await database.characterModeDao.getIdentityOverride(clonedId),
        isNotNull,
      );
    },
  );

  test(
    'mode lifecycle protects the only mode and persists last used mode',
    () async {
      final repository = CharacterModeRepositoryImpl(database);
      final baseId = await repository.createMode(
        projectId: 'project-1',
        characterId: 'character-1',
        name: 'Base Mode',
        isDefault: true,
      );
      await expectLater(repository.deleteMode(baseId), throwsStateError);
      final combatId = await repository.createMode(
        projectId: 'project-1',
        characterId: 'character-1',
        name: 'Combat Mode',
      );
      await repository.rememberLastUsedMode(
        characterId: 'character-1',
        modeId: combatId,
      );
      expect(await repository.getLastUsedMode('character-1'), combatId);
      await repository.deleteMode(combatId);
      expect(await repository.getMode(baseId), isNotNull);
    },
  );

  test('mode references persist and derived relations are removable', () async {
    final modeRepository = CharacterModeRepositoryImpl(database);
    final modeId = await modeRepository.createMode(
      projectId: 'project-1',
      characterId: 'character-1',
      name: 'Combat Mode',
    );
    final referenceRepository = CharacterModeReferenceRepository(database);
    await referenceRepository.add(
      modeId: modeId,
      referenceType: 'full_body',
      filePath: 'references/full-body.png',
    );
    expect(await referenceRepository.getReferences(modeId), hasLength(1));
  });
}
