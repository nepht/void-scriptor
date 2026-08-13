// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faction_repository.dart';

// ignore_for_file: type=lint
mixin _$FactionRepositoryMixin on DatabaseAccessor<ProjectDatabase> {
  $FactionsTable get factions => attachedDatabase.factions;
  $FactionUnitsTable get factionUnits => attachedDatabase.factionUnits;
  FactionRepositoryManager get managers => FactionRepositoryManager(this);
}

class FactionRepositoryManager {
  final _$FactionRepositoryMixin _db;
  FactionRepositoryManager(this._db);
  $$FactionsTableTableManager get factions =>
      $$FactionsTableTableManager(_db.attachedDatabase, _db.factions);
  $$FactionUnitsTableTableManager get factionUnits =>
      $$FactionUnitsTableTableManager(_db.attachedDatabase, _db.factionUnits);
}
