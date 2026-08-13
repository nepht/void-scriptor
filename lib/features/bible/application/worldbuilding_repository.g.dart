// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worldbuilding_repository.dart';

// ignore_for_file: type=lint
mixin _$WorldbuildingRepositoryMixin on DatabaseAccessor<ProjectDatabase> {
  $SpeciesTable get species => attachedDatabase.species;
  $TechnologiesTable get technologies => attachedDatabase.technologies;
  $PowerSystemsTable get powerSystems => attachedDatabase.powerSystems;
  $PowerAbilitiesTable get powerAbilities => attachedDatabase.powerAbilities;
  WorldbuildingRepositoryManager get managers =>
      WorldbuildingRepositoryManager(this);
}

class WorldbuildingRepositoryManager {
  final _$WorldbuildingRepositoryMixin _db;
  WorldbuildingRepositoryManager(this._db);
  $$SpeciesTableTableManager get species =>
      $$SpeciesTableTableManager(_db.attachedDatabase, _db.species);
  $$TechnologiesTableTableManager get technologies =>
      $$TechnologiesTableTableManager(_db.attachedDatabase, _db.technologies);
  $$PowerSystemsTableTableManager get powerSystems =>
      $$PowerSystemsTableTableManager(_db.attachedDatabase, _db.powerSystems);
  $$PowerAbilitiesTableTableManager get powerAbilities =>
      $$PowerAbilitiesTableTableManager(
        _db.attachedDatabase,
        _db.powerAbilities,
      );
}
