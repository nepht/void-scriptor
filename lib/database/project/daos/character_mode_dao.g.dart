// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_mode_dao.dart';

// ignore_for_file: type=lint
mixin _$CharacterModeDaoMixin on DatabaseAccessor<ProjectDatabase> {
  $CharacterModesTable get characterModes => attachedDatabase.characterModes;
  $CharacterLoadoutEntriesTable get characterLoadoutEntries =>
      attachedDatabase.characterLoadoutEntries;
  $CharacterModeIdentityOverridesTable get characterModeIdentityOverrides =>
      attachedDatabase.characterModeIdentityOverrides;
  $CharacterModeReferencesTable get characterModeReferences =>
      attachedDatabase.characterModeReferences;
  CharacterModeDaoManager get managers => CharacterModeDaoManager(this);
}

class CharacterModeDaoManager {
  final _$CharacterModeDaoMixin _db;
  CharacterModeDaoManager(this._db);
  $$CharacterModesTableTableManager get characterModes =>
      $$CharacterModesTableTableManager(
        _db.attachedDatabase,
        _db.characterModes,
      );
  $$CharacterLoadoutEntriesTableTableManager get characterLoadoutEntries =>
      $$CharacterLoadoutEntriesTableTableManager(
        _db.attachedDatabase,
        _db.characterLoadoutEntries,
      );
  $$CharacterModeIdentityOverridesTableTableManager
  get characterModeIdentityOverrides =>
      $$CharacterModeIdentityOverridesTableTableManager(
        _db.attachedDatabase,
        _db.characterModeIdentityOverrides,
      );
  $$CharacterModeReferencesTableTableManager get characterModeReferences =>
      $$CharacterModeReferencesTableTableManager(
        _db.attachedDatabase,
        _db.characterModeReferences,
      );
}
