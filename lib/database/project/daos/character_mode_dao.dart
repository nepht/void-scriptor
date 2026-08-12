import 'package:drift/drift.dart';

import '../project_database.dart';
import '../tables/character_modes.dart';
import '../tables/character_loadout_entries.dart';
import '../tables/character_mode_identity_overrides.dart';
import '../tables/character_mode_references.dart';

part 'character_mode_dao.g.dart';

@DriftAccessor(
  tables: [
    CharacterModes,
    CharacterLoadoutEntries,
    CharacterModeIdentityOverrides,
    CharacterModeReferences,
  ],
)
class CharacterModeDao extends DatabaseAccessor<ProjectDatabase>
    with _$CharacterModeDaoMixin {
  CharacterModeDao(super.db);

  Future<List<CharacterMode>> getModes(String characterId) =>
      (select(characterModes)
            ..where((row) => row.characterId.equals(characterId))
            ..orderBy([
              (row) => OrderingTerm(
                expression: row.isDefault,
                mode: OrderingMode.desc,
              ),
              (row) => OrderingTerm(expression: row.name),
            ]))
          .get();

  Future<CharacterMode?> getMode(String modeId) => (select(
    characterModes,
  )..where((row) => row.id.equals(modeId))).getSingleOrNull();

  Future<void> insertMode(CharacterModesCompanion mode) =>
      into(characterModes).insert(mode);

  Future<void> updateMode(CharacterModesCompanion mode) => (update(
    characterModes,
  )..where((row) => row.id.equals(mode.id.value))).write(mode);

  Future<int> deleteMode(String modeId) =>
      (delete(characterModes)..where((row) => row.id.equals(modeId))).go();

  Future<int> countCharacterModes(String characterId) async =>
      (selectOnly(characterModes)
            ..addColumns([characterModes.id.count()])
            ..where(characterModes.characterId.equals(characterId)))
          .map((row) => row.read(characterModes.id.count()) ?? 0)
          .getSingle();

  Future<void> removeCharacterModes(String characterId) async {
    final modes = await (select(
      characterModes,
    )..where((row) => row.characterId.equals(characterId))).get();
    for (final mode in modes) {
      await (delete(
        characterLoadoutEntries,
      )..where((row) => row.modeId.equals(mode.id))).go();
      await (delete(
        characterModeIdentityOverrides,
      )..where((row) => row.modeId.equals(mode.id))).go();
      await (delete(
        characterModeReferences,
      )..where((row) => row.modeId.equals(mode.id))).go();
    }
    await (delete(
      characterModes,
    )..where((row) => row.characterId.equals(characterId))).go();
  }

  Future<List<CharacterLoadoutEntry>> getLoadout(String modeId) =>
      (select(characterLoadoutEntries)
            ..where((row) => row.modeId.equals(modeId))
            ..orderBy([(row) => OrderingTerm(expression: row.sortOrder)]))
          .get();

  Future<void> insertLoadoutEntry(CharacterLoadoutEntriesCompanion entry) =>
      into(characterLoadoutEntries).insert(entry);

  Future<int> deleteLoadoutEntry(String entryId) => (delete(
    characterLoadoutEntries,
  )..where((row) => row.id.equals(entryId))).go();

  Future<CharacterModeIdentityOverride?> getIdentityOverride(String modeId) =>
      (select(
        characterModeIdentityOverrides,
      )..where((row) => row.modeId.equals(modeId))).getSingleOrNull();

  Future<void> upsertIdentityOverride(
    CharacterModeIdentityOverridesCompanion override,
  ) => into(characterModeIdentityOverrides).insertOnConflictUpdate(override);

  Future<List<CharacterModeReference>> getReferences(String modeId) =>
      (select(characterModeReferences)
            ..where((row) => row.modeId.equals(modeId))
            ..orderBy([(row) => OrderingTerm(expression: row.priority)]))
          .get();
}
