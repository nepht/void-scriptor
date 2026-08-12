// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weapon_dao.dart';

// ignore_for_file: type=lint
mixin _$WeaponDaoMixin on DatabaseAccessor<ProjectDatabase> {
  $WeaponsTable get weapons => attachedDatabase.weapons;
  $WeaponComponentsTable get weaponComponents =>
      attachedDatabase.weaponComponents;
  $WeaponMeasurementsTable get weaponMeasurements =>
      attachedDatabase.weaponMeasurements;
  $WeaponColorsTable get weaponColors => attachedDatabase.weaponColors;
  $WeaponEnergyProfilesTable get weaponEnergyProfiles =>
      attachedDatabase.weaponEnergyProfiles;
  $WeaponVariantsTable get weaponVariants => attachedDatabase.weaponVariants;
  $WeaponReferencesTable get weaponReferences =>
      attachedDatabase.weaponReferences;
  $WeaponPreservationProfilesTable get weaponPreservationProfiles =>
      attachedDatabase.weaponPreservationProfiles;
  WeaponDaoManager get managers => WeaponDaoManager(this);
}

class WeaponDaoManager {
  final _$WeaponDaoMixin _db;
  WeaponDaoManager(this._db);
  $$WeaponsTableTableManager get weapons =>
      $$WeaponsTableTableManager(_db.attachedDatabase, _db.weapons);
  $$WeaponComponentsTableTableManager get weaponComponents =>
      $$WeaponComponentsTableTableManager(
        _db.attachedDatabase,
        _db.weaponComponents,
      );
  $$WeaponMeasurementsTableTableManager get weaponMeasurements =>
      $$WeaponMeasurementsTableTableManager(
        _db.attachedDatabase,
        _db.weaponMeasurements,
      );
  $$WeaponColorsTableTableManager get weaponColors =>
      $$WeaponColorsTableTableManager(_db.attachedDatabase, _db.weaponColors);
  $$WeaponEnergyProfilesTableTableManager get weaponEnergyProfiles =>
      $$WeaponEnergyProfilesTableTableManager(
        _db.attachedDatabase,
        _db.weaponEnergyProfiles,
      );
  $$WeaponVariantsTableTableManager get weaponVariants =>
      $$WeaponVariantsTableTableManager(
        _db.attachedDatabase,
        _db.weaponVariants,
      );
  $$WeaponReferencesTableTableManager get weaponReferences =>
      $$WeaponReferencesTableTableManager(
        _db.attachedDatabase,
        _db.weaponReferences,
      );
  $$WeaponPreservationProfilesTableTableManager
  get weaponPreservationProfiles =>
      $$WeaponPreservationProfilesTableTableManager(
        _db.attachedDatabase,
        _db.weaponPreservationProfiles,
      );
}
