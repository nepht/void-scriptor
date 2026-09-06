// Stand-alone asset creation contract (product contract, Choirudin 2026-09-06):
// Wardrobe, Weapon, Armor, Accessory, and Story Item (prop) are all created
// as stand-alone project assets via one generalized DAO entry point.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';

void main() {
  late ProjectDatabase database;

  setUp(() async {
    database = ProjectDatabase(NativeDatabase.memory());
    await database.initialize();
  });

  tearDown(() => database.close());

  test('generalized creation supports the five stand-alone types', () async {
    const types = <String>['wardrobe', 'weapon', 'armor', 'accessory', 'prop'];
    for (var i = 0; i < types.length; i++) {
      await database.assetDao.createStandaloneAsset(
        id: 'asset-$i',
        projectId: 'project-1',
        name: 'Standalone ${types[i]}',
        description: 'Katalog proyek.',
        type: types[i],
        now: DateTime(2026),
      );
    }
    for (var i = 0; i < types.length; i++) {
      expect((await database.assetDao.getById('asset-$i'))?.type, types[i]);
    }
  });

  test('generalized creation rejects types outside the stand-alone set', () {
    expect(
      () => database.assetDao.createStandaloneAsset(
        id: 'bad-1',
        projectId: 'project-1',
        name: 'Not stand-alone',
        type: 'character',
        now: DateTime(2026),
      ),
      throwsArgumentError,
    );
  });

  test('generalized creation rejects blank names', () {
    expect(
      () => database.assetDao.createStandaloneAsset(
        id: 'bad-2',
        projectId: 'project-1',
        name: '   ',
        type: 'armor',
        now: DateTime(2026),
      ),
      throwsArgumentError,
    );
  });
}
