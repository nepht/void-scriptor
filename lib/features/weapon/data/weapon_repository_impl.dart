import 'dart:io';

import '../../../core/persistence/project_paths.dart';
import '../../../database/project/project_database.dart';
import '../domain/weapon_model.dart';
import '../domain/weapon_repository.dart';
import '../domain/weapon_workspace_data.dart';

class WeaponRepositoryImpl implements WeaponRepository {
  WeaponRepositoryImpl({
    required this.database,
    required this.projectId,
    ProjectPaths? paths,
  }) : paths = paths ?? ProjectPaths();

  final ProjectDatabase database;
  final String projectId;
  final ProjectPaths paths;

  @override
  Future<List<WeaponModel>> getWeapons() async =>
      (await database.weaponDao.getWeapons(projectId)).map(_map).toList();

  @override
  Future<WeaponModel?> getWeapon(String assetId) async {
    final row = await database.weaponDao.getWeapon(assetId);
    return row == null ? null : _map(row);
  }

  @override
  Future<WeaponWorkspaceData> getWorkspaceData(String assetId) async {
    final components = await database.weaponDao.getComponents(assetId);
    final measurements = await database.weaponDao.getMeasurements(assetId);
    final energy = await database.weaponDao.getEnergyProfile(assetId);
    final variants = await database.weaponDao.getVariants(assetId);
    final references = await database.weaponDao.getReferences(assetId);
    return WeaponWorkspaceData(
      components: [
        for (final component in components)
          WeaponComponentInfo(
            name: component.name,
            componentType: component.componentType,
          ),
      ],
      measurements: [
        for (final measurement in measurements)
          WeaponMeasurementInfo(
            label: measurement.label,
            value: measurement.value,
            unit: measurement.unit,
          ),
      ],
      energy: energy == null
          ? null
          : WeaponEnergyInfo(
              activation: energy.activation,
              emissionColor: energy.emissionColor,
              behavior: energy.behavior,
            ),
      variants: [
        for (final variant in variants)
          WeaponVariantInfo(name: variant.name, isDefault: variant.isDefault),
      ],
      references: [
        for (final reference in references)
          WeaponReferenceInfo(
            referenceType: reference.referenceType,
            filePath: reference.filePath,
          ),
      ],
    );
  }

  @override
  Future<void> deleteWeapon(String assetId) async {
    await database.transaction(() async {
      await database.assetDao.removeAssetData(assetId);
      await (database.delete(
        database.weaponComponents,
      )..where((row) => row.weaponId.equals(assetId))).go();
      await (database.delete(
        database.weaponMeasurements,
      )..where((row) => row.weaponId.equals(assetId))).go();
      await (database.delete(
        database.weaponColors,
      )..where((row) => row.weaponId.equals(assetId))).go();
      await (database.delete(
        database.weaponEnergyProfiles,
      )..where((row) => row.weaponId.equals(assetId))).go();
      await (database.delete(
        database.weaponVariants,
      )..where((row) => row.weaponId.equals(assetId))).go();
      await (database.delete(
        database.weaponReferences,
      )..where((row) => row.weaponId.equals(assetId))).go();
      await (database.delete(
        database.weaponPreservationProfiles,
      )..where((row) => row.weaponId.equals(assetId))).go();
      await (database.delete(
        database.weapons,
      )..where((row) => row.assetId.equals(assetId))).go();
      await (database.delete(
        database.assets,
      )..where((row) => row.id.equals(assetId))).go();
    });
    final project = await paths.project(projectId);
    final directory = Directory(
      '${project.path}${Platform.pathSeparator}assets${Platform.pathSeparator}weapons${Platform.pathSeparator}$assetId',
    );
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  WeaponModel _map(Weapon row) => WeaponModel(
    assetId: row.assetId,
    projectId: row.projectId,
    name: row.name,
    weaponType: row.weaponType,
    description: row.description,
    primaryMaterial: row.primaryMaterial,
    secondaryMaterial: row.secondaryMaterial,
    energyType: row.energyType,
    coreType: row.coreType,
    lengthMm: row.lengthMm,
    weightKg: row.weightKg,
    notes: row.notes,
  );
}
