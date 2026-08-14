import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/assets/domain/asset_model.dart';
import 'package:void_scriptor/features/assets/domain/asset_relation_type.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/character/domain/character_identity_profile.dart'
    as domain;
import 'package:void_scriptor/features/character/domain/character_model.dart';
import 'package:void_scriptor/features/character/application/create_character_service.dart';

void main() {
  test('AssetModel round-trips type, tags, and metadata contract', () {
    final asset = AssetModel(
      id: 'asset-1',
      projectId: 'project-1',
      name: 'Qowner',
      type: AssetType.character,
      version: '1.0.0',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      tags: const ['void', 'main-character'],
    );

    expect(asset.type, AssetType.character);
    expect(asset.tags, contains('void'));
    expect(asset.copyWith(name: 'Qowner Prime').name, 'Qowner Prime');
  });

  test('CharacterModel and identity profile expose locked identity fields', () {
    const character = CharacterModel(
      assetId: 'char-1',
      projectId: 'project-1',
      displayName: 'Qowner',
      hair: 'white',
      eyes: 'violet',
    );
    const identity = domain.CharacterIdentityProfile(characterId: 'char-1');

    expect(character.displayName, 'Qowner');
    expect(character.hair, 'white');
    expect(identity.faceLock, isTrue);
    expect(identity.outfitLock, isFalse);
  });

  test('project database migrates to asset and character schema', () async {
    final root = await Directory.systemTemp.createTemp('s08-schema-');
    addTearDown(() => root.delete(recursive: true));
    final path = ProjectPaths(rootDirectory: root);
    final databasePath = (await path.database('project-1')).path;

    await ProjectDatabaseService().create(databasePath);
    final database = await ProjectDatabaseService().open(databasePath);
    addTearDown(database.close);

    expect(database.schemaVersion, 33);
    expect(await database.select(database.assets).get(), isEmpty);
    expect(await database.select(database.characters).get(), isEmpty);
  });

  test(
    'CreateCharacterService creates asset, character, identity, and folders',
    () async {
      final root = await Directory.systemTemp.createTemp('s08-create-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      final databasePath = (await paths.database('project-1')).path;
      await ProjectDatabaseService().create(databasePath);
      final database = await ProjectDatabaseService().open(databasePath);
      addTearDown(database.close);

      final service = CreateCharacterService(database: database, paths: paths);
      final id = await service.create(projectId: 'project-1', name: 'Qowner');

      expect(id, isNotEmpty);
      expect(
        (await database.select(database.assets).get()).single.name,
        'Qowner',
      );
      expect(
        (await database.select(database.characters).get()).single.assetId,
        id,
      );
      expect(
        (await database.select(database.characterIdentityProfiles).get())
            .single
            .characterId,
        id,
      );
      final modes = await database.characterModeDao.getModes(id);
      expect(modes, hasLength(1));
      expect(modes.single.name, 'Base Mode');
      expect(modes.single.isDefault, isTrue);
      expect(
        await database.characterModeDao.getIdentityOverride(modes.single.id),
        isNotNull,
      );
      expect(
        await Directory(
          '${root.path}/project-1/assets/characters/$id',
        ).exists(),
        isTrue,
      );
      expect(AssetRelationType.uses.value, 'uses');
      expect(AssetRelationType.appearsIn.value, 'appears_in');
    },
  );
}
