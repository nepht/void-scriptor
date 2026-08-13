// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creature_repository.dart';

// ignore_for_file: type=lint
mixin _$CreatureRepositoryMixin on DatabaseAccessor<ProjectDatabase> {
  $CreaturesTable get creatures => attachedDatabase.creatures;
  $CreaturePhysicalProfilesTable get creaturePhysicalProfiles =>
      attachedDatabase.creaturePhysicalProfiles;
  $CreatureAbilitiesTable get creatureAbilities =>
      attachedDatabase.creatureAbilities;
  $CreatureModesTable get creatureModes => attachedDatabase.creatureModes;
  CreatureRepositoryManager get managers => CreatureRepositoryManager(this);
}

class CreatureRepositoryManager {
  final _$CreatureRepositoryMixin _db;
  CreatureRepositoryManager(this._db);
  $$CreaturesTableTableManager get creatures =>
      $$CreaturesTableTableManager(_db.attachedDatabase, _db.creatures);
  $$CreaturePhysicalProfilesTableTableManager get creaturePhysicalProfiles =>
      $$CreaturePhysicalProfilesTableTableManager(
        _db.attachedDatabase,
        _db.creaturePhysicalProfiles,
      );
  $$CreatureAbilitiesTableTableManager get creatureAbilities =>
      $$CreatureAbilitiesTableTableManager(
        _db.attachedDatabase,
        _db.creatureAbilities,
      );
  $$CreatureModesTableTableManager get creatureModes =>
      $$CreatureModesTableTableManager(_db.attachedDatabase, _db.creatureModes);
}
