// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_repository.dart';

// ignore_for_file: type=lint
mixin _$VehicleRepositoryMixin on DatabaseAccessor<ProjectDatabase> {
  $VehiclesTable get vehicles => attachedDatabase.vehicles;
  $VehicleSpecificationsTable get vehicleSpecifications =>
      attachedDatabase.vehicleSpecifications;
  $VehicleComponentsTable get vehicleComponents =>
      attachedDatabase.vehicleComponents;
  $VehicleWeaponMountsTable get vehicleWeaponMounts =>
      attachedDatabase.vehicleWeaponMounts;
  $VehicleVariantsTable get vehicleVariants => attachedDatabase.vehicleVariants;
  VehicleRepositoryManager get managers => VehicleRepositoryManager(this);
}

class VehicleRepositoryManager {
  final _$VehicleRepositoryMixin _db;
  VehicleRepositoryManager(this._db);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db.attachedDatabase, _db.vehicles);
  $$VehicleSpecificationsTableTableManager get vehicleSpecifications =>
      $$VehicleSpecificationsTableTableManager(
        _db.attachedDatabase,
        _db.vehicleSpecifications,
      );
  $$VehicleComponentsTableTableManager get vehicleComponents =>
      $$VehicleComponentsTableTableManager(
        _db.attachedDatabase,
        _db.vehicleComponents,
      );
  $$VehicleWeaponMountsTableTableManager get vehicleWeaponMounts =>
      $$VehicleWeaponMountsTableTableManager(
        _db.attachedDatabase,
        _db.vehicleWeaponMounts,
      );
  $$VehicleVariantsTableTableManager get vehicleVariants =>
      $$VehicleVariantsTableTableManager(
        _db.attachedDatabase,
        _db.vehicleVariants,
      );
}
