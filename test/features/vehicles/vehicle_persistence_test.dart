import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/vehicles/application/create_vehicle_service.dart';
import 'package:void_scriptor/features/vehicles/data/vehicle_repository.dart';
import 'package:void_scriptor/features/vehicles/domain/vehicle_model.dart';

void main() {
  test('vehicle production package survives database restart', () async {
    final root = await Directory.systemTemp.createTemp('s22-vehicle-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final dbPath = (await paths.database('project-1')).path;
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final first = await service.open(dbPath);
    final id = await CreateVehicleService(database: first, paths: paths).create(
      projectId: 'project-1',
      name: 'Neo Interceptor',
      category: VehicleCategory.spacecraft,
      manufacturer: 'Neo Forge',
      role: 'Interceptor',
    );
    final repository = VehicleRepository(first);
    await repository.saveSpecification(
      VehicleSpecification(
        vehicleId: id,
        lengthMeters: 18,
        crew: 1,
        propulsion: 'Void Thruster',
      ),
    );
    await repository.saveComponent(
      VehicleComponentModel(id: 'core', vehicleId: id, name: 'Void Core'),
    );
    await repository.saveWeaponMount(
      VehicleWeaponMountModel(
        id: 'mount-1',
        vehicleId: id,
        weaponId: 'weapon-1',
        mountName: 'Nose Mount',
        quantity: 2,
      ),
    );
    await repository.saveVariant(
      VehicleVariantModel(
        id: 'combat',
        vehicleId: id,
        name: 'Combat',
        referenceSetId: 'vehicle-combat',
      ),
    );
    await first.close();

    final second = await service.open(dbPath);
    addTearDown(second.close);
    final restored = VehicleRepository(second);
    expect(second.schemaVersion, 41);
    expect((await second.assetDao.getById(id))?.type, 'vehicle');
    expect(
      (await restored.getVehicle(id))?.category,
      VehicleCategory.spacecraft,
    );
    expect((await restored.getSpecification(id))?.crew, 1);
    expect((await restored.componentsFor(id)).single.name, 'Void Core');
    expect((await restored.weaponMountsFor(id)).single.quantity, 2);
    expect(
      (await restored.variantsFor(id)).single.referenceSetId,
      'vehicle-combat',
    );
    expect(
      await Directory(
        '${(await paths.project('project-1')).path}${Platform.pathSeparator}assets${Platform.pathSeparator}vehicles${Platform.pathSeparator}$id${Platform.pathSeparator}references${Platform.pathSeparator}technical',
      ).exists(),
      isTrue,
    );
  });
}
