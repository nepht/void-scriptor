import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../database/project/project_database.dart' as db;
import '../domain/loadout_slot.dart';

abstract interface class CharacterLoadoutRepository {
  Future<List<db.CharacterLoadoutEntry>> getLoadout(String modeId);
  Future<void> setSlot({
    required String modeId,
    required LoadoutSlot slot,
    required String assetId,
    int quantity = 1,
  });
  Future<void> removeSlot({
    required String modeId,
    required LoadoutSlot slot,
    required String assetId,
  });

  /// Rewrites the quantity of one existing entry in place (no duplicates).
  Future<void> updateQuantity({
    required String modeId,
    required String slotValue,
    required String assetId,
    required int quantity,
  });
}

class CharacterLoadoutRepositoryImpl implements CharacterLoadoutRepository {
  CharacterLoadoutRepositoryImpl(this.database);

  final db.ProjectDatabase database;

  @override
  Future<List<db.CharacterLoadoutEntry>> getLoadout(String modeId) =>
      database.characterModeDao.getLoadout(modeId);

  @override
  Future<void> setSlot({
    required String modeId,
    required LoadoutSlot slot,
    required String assetId,
    int quantity = 1,
  }) async {
    final mode = await database.characterModeDao.getMode(modeId);
    if (mode == null) throw ArgumentError('Mode not found');
    final asset = await database.assetDao.getById(assetId);
    if (asset == null) throw ArgumentError('Asset not found');
    final quantityError = validateLoadoutQuantity(slot, quantity);
    if (quantityError != null) throw ArgumentError(quantityError);
    if (asset.type != slot.assetType) {
      throw ArgumentError(
        'Asset type ${asset.type} is invalid for ${slot.value}',
      );
    }

    await database.transaction(() async {
      // vs-hunt-20260913-loadout LDT-BUG-03: setSlot adalah operasi SET per
      // (modeId, slot) untuk SEMUA multiplicity. Branch 'single only' yang
      // lama membuat replace pada accessory/carried_item menyisipkan baris
      // kedua sambil meninggalkan ikatan lama — penumpukan senyap yang tidak
      // pernah terlihat dialog (editor menyimpan satu nilai per slot).
      // Kontrak 'no duplicates for multiple slots' yang sudah dikunci
      // updateQuantity kini ditegakkan di jalur set juga.
      await (database.delete(database.characterLoadoutEntries)..where(
            (row) => row.modeId.equals(modeId) & row.slot.equals(slot.value),
          ))
          .go();
      await database.characterModeDao.insertLoadoutEntry(
        db.CharacterLoadoutEntriesCompanion.insert(
          id: const Uuid().v4(),
          modeId: modeId,
          assetId: assetId,
          slot: slot.value,
          quantity: Value(quantity),
        ),
      );
      final relationType = switch (asset.type) {
        'weapon' => 'uses',
        'wardrobe' => 'wears',
        _ => null,
      };
      if (relationType == null) return;
      final existing =
          await (database.select(database.assetRelations)..where(
                (row) =>
                    row.sourceAssetId.equals(mode.characterId) &
                    row.targetAssetId.equals(assetId) &
                    row.relationType.equals(relationType) &
                    row.relationOrigin.equals('derived'),
              ))
              .getSingleOrNull();
      if (existing == null) {
        await database
            .into(database.assetRelations)
            .insert(
              db.AssetRelationsCompanion.insert(
                id: const Uuid().v4(),
                projectId: Value(mode.projectId),
                sourceAssetId: mode.characterId,
                targetAssetId: assetId,
                relationType: relationType,
                relationOrigin: const Value('derived'),
              ),
            );
      }
    });
  }

  @override
  Future<void> removeSlot({
    required String modeId,
    required LoadoutSlot slot,
    required String assetId,
  }) async {
    final mode = await database.characterModeDao.getMode(modeId);
    if (mode == null) throw ArgumentError('Mode not found');
    await (database.delete(database.characterLoadoutEntries)..where(
          (row) =>
              row.modeId.equals(modeId) &
              row.assetId.equals(assetId) &
              row.slot.equals(slot.value),
        ))
        .go();
    final entries = database.characterLoadoutEntries;
    final modes = database.characterModes;
    final stillUsed =
        await (database.select(entries).join([
              innerJoin(modes, modes.id.equalsExp(entries.modeId)),
            ])..where(
              entries.assetId.equals(assetId) &
                  modes.characterId.equals(mode.characterId),
            ))
            .get();
    if (stillUsed.isNotEmpty) return;
    final relationType = slot.assetType == 'weapon'
        ? 'uses'
        : slot.assetType == 'wardrobe'
        ? 'wears'
        : null;
    if (relationType == null) return;
    await (database.delete(database.assetRelations)..where(
          (row) =>
              row.sourceAssetId.equals(mode.characterId) &
              row.targetAssetId.equals(assetId) &
              row.relationType.equals(relationType) &
              row.relationOrigin.equals('derived'),
        ))
        .go();
  }

  @override
  Future<void> updateQuantity({
    required String modeId,
    required String slotValue,
    required String assetId,
    required int quantity,
  }) async {
    final slot = slotValue.loadoutSlot;
    if (slot == null) {
      throw ArgumentError('Unknown loadout slot: $slotValue');
    }
    final quantityError = validateLoadoutQuantity(slot, quantity);
    if (quantityError != null) throw ArgumentError(quantityError);
    final updated =
        await (database.update(database.characterLoadoutEntries)..where(
              (row) =>
                  row.modeId.equals(modeId) &
                  row.assetId.equals(assetId) &
                  row.slot.equals(slotValue),
            ))
            .write(
              db.CharacterLoadoutEntriesCompanion(quantity: Value(quantity)),
            );
    if (updated == 0) {
      throw ArgumentError('Loadout entry not found for quantity update');
    }
  }
}
