// Stand-alone asset creation contract (product contract, Choirudin
// 2026-09-06): Wardrobe, Weapon, Armor, Accessory, Story Item (prop),
// Creature, and Vehicle are all created as stand-alone project assets via
// one generalized DAO entry point. Companion maps to the creature type;
// hair_variant stays deferred (slot exists, no creation path by design).
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character_mode/domain/loadout_slot.dart';

void main() {
  late ProjectDatabase database;

  setUp(() async {
    database = ProjectDatabase(NativeDatabase.memory());
    await database.initialize();
  });

  tearDown(() => database.close());

  test('generalized creation supports the seven stand-alone types', () async {
    const types = <String>[
      'wardrobe',
      'weapon',
      'armor',
      'accessory',
      'prop',
      'creature',
      'vehicle',
    ];
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

  test('companion slot resolves to creature asset type', () {
    // Product decision (Choirudin, 2026-09-06): a companion is a creature.
    expect(LoadoutSlot.companion.assetType, 'creature');
    expect(LoadoutSlot.vehicle.assetType, 'vehicle');
  });

  test('quantity validation still permits multi for weapons/carried', () {
    expect(validateLoadoutQuantity(LoadoutSlot.carriedItem, 3), isNull);
    expect(validateLoadoutQuantity(LoadoutSlot.primaryWeapon, 2), isNull);
    expect(validateLoadoutQuantity(LoadoutSlot.companion, 2), isNotNull);
  });
}
