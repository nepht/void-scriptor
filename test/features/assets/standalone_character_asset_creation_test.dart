import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';

void main() {
  test('creates stand-alone armor and story-item assets', () async {
    final database = ProjectDatabase(NativeDatabase.memory());
    await database.initialize();
    addTearDown(database.close);

    await database.assetDao.createStandaloneCharacterAsset(
      id: 'armor-1',
      projectId: 'project-1',
      name: 'Void Guard',
      description: 'Armor milik katalog proyek.',
      type: 'armor',
      now: DateTime(2026),
    );
    await database.assetDao.createStandaloneCharacterAsset(
      id: 'prop-1',
      projectId: 'project-1',
      name: 'Memory Shard',
      description: 'Story item yang dapat dibawa karakter.',
      type: 'prop',
      now: DateTime(2026),
    );

    expect((await database.assetDao.getById('armor-1'))?.type, 'armor');
    expect((await database.assetDao.getById('prop-1'))?.type, 'prop');
  });

  test('rejects asset types outside armor and prop', () async {
    final database = ProjectDatabase(NativeDatabase.memory());
    await database.initialize();
    addTearDown(database.close);

    expect(
      () => database.assetDao.createStandaloneCharacterAsset(
        id: 'character-1',
        projectId: 'project-1',
        name: 'Not allowed',
        type: 'character',
        now: DateTime(2026),
      ),
      throwsArgumentError,
    );
  });
}
