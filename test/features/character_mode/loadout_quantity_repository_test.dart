// Quantity-only update contract: changing quantity of an existing loadout
// entry must rewrite that row in place (no duplicates for multiple slots),
// reject invalid quantities, and fail loudly for missing entries.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character_mode/data/character_loadout_repository_impl.dart';

void main() {
  late ProjectDatabase database;

  setUp(() async {
    database = ProjectDatabase(NativeDatabase.memory());
    await database.initialize();
  });

  tearDown(() => database.close());

  Future<void> seedEntry({
    required String id,
    required String slot,
    int quantity = 1,
  }) => database.characterModeDao.insertLoadoutEntry(
    CharacterLoadoutEntriesCompanion.insert(
      id: id,
      modeId: 'mode-1',
      assetId: 'asset-1',
      slot: slot,
      quantity: Value(quantity),
    ),
  );

  test('updates quantity in place for a multiple slot', () async {
    await seedEntry(id: 'e1', slot: 'carried_item');
    final repository = CharacterLoadoutRepositoryImpl(database);

    await repository.updateQuantity(
      modeId: 'mode-1',
      slotValue: 'carried_item',
      assetId: 'asset-1',
      quantity: 3,
    );

    final rows = await database.characterModeDao.getLoadout('mode-1');
    expect(rows, hasLength(1));
    expect(rows.single.quantity, 3);
  });

  test('rejects invalid quantity and missing entries', () async {
    await seedEntry(id: 'e1', slot: 'carried_item');
    final repository = CharacterLoadoutRepositoryImpl(database);

    expect(
      () => repository.updateQuantity(
        modeId: 'mode-1',
        slotValue: 'carried_item',
        assetId: 'asset-1',
        quantity: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => repository.updateQuantity(
        modeId: 'mode-1',
        slotValue: 'carried_item',
        assetId: 'missing-asset',
        quantity: 2,
      ),
      throwsArgumentError,
    );
  });
}
