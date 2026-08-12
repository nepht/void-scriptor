import 'package:drift/drift.dart';

import '../project_database.dart';
import '../tables/weapons.dart';
import '../tables/weapon_components.dart';
import '../tables/weapon_measurements.dart';
import '../tables/weapon_colors.dart';
import '../tables/weapon_energy_profiles.dart';
import '../tables/weapon_variants.dart';
import '../tables/weapon_references.dart';
import '../tables/weapon_preservation_profiles.dart';

part 'weapon_dao.g.dart';

@DriftAccessor(
  tables: [
    Weapons,
    WeaponComponents,
    WeaponMeasurements,
    WeaponColors,
    WeaponEnergyProfiles,
    WeaponVariants,
    WeaponReferences,
    WeaponPreservationProfiles,
  ],
)
class WeaponDao extends DatabaseAccessor<ProjectDatabase>
    with _$WeaponDaoMixin {
  WeaponDao(super.db);

  Future<Weapon?> getWeapon(String assetId) => (select(
    weapons,
  )..where((row) => row.assetId.equals(assetId))).getSingleOrNull();

  Future<List<Weapon>> getWeapons(String projectId) =>
      (select(weapons)..where((row) => row.projectId.equals(projectId))).get();

  Future<void> insertWeapon(WeaponsCompanion entry) =>
      into(weapons).insert(entry);

  Future<WeaponVariant?> getDefaultVariant(String weaponId) =>
      (select(weaponVariants)
            ..where((row) => row.weaponId.equals(weaponId))
            ..where((row) => row.isDefault.equals(true)))
          .getSingleOrNull();

  Future<List<WeaponVariant>> getVariants(String weaponId) => (select(
    weaponVariants,
  )..where((row) => row.weaponId.equals(weaponId))).get();

  Future<List<WeaponComponent>> getComponents(String weaponId) =>
      (select(weaponComponents)
            ..where((row) => row.weaponId.equals(weaponId))
            ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
          .get();

  Future<List<WeaponMeasurement>> getMeasurements(String weaponId) =>
      (select(weaponMeasurements)
            ..where((row) => row.weaponId.equals(weaponId))
            ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
          .get();

  Future<List<WeaponColor>> getColors(String weaponId) =>
      (select(weaponColors)
            ..where((row) => row.weaponId.equals(weaponId))
            ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
          .get();

  Future<WeaponEnergyProfile?> getEnergyProfile(String weaponId) => (select(
    weaponEnergyProfiles,
  )..where((row) => row.weaponId.equals(weaponId))).getSingleOrNull();

  Future<List<WeaponReference>> getReferences(String weaponId) =>
      (select(weaponReferences)
            ..where((row) => row.weaponId.equals(weaponId))
            ..orderBy([(row) => OrderingTerm.asc(row.priority)]))
          .get();

  Future<WeaponPreservationProfile?> getPreservationProfile(String weaponId) =>
      (select(
        weaponPreservationProfiles,
      )..where((row) => row.weaponId.equals(weaponId))).getSingleOrNull();
}
