import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creatures/domain/creature_model.dart';
import 'package:void_scriptor/features/production_assets/application/production_asset_detail.dart';
import 'package:void_scriptor/features/production_assets/presentation/production_asset_workspace_screen.dart';
import 'package:void_scriptor/features/props/domain/prop_model.dart';
import 'package:void_scriptor/features/vehicles/domain/vehicle_model.dart';

void main() {
  test('resolves creature detail sheet from domain models', () {
    const creature = CreatureModel(
      assetId: 'c1',
      projectId: 'p1',
      name: 'Byte',
      category: CreatureCategory.companion,
      description: 'A loyal synthetic companion.',
    );
    const profile = CreaturePhysicalProfile(
      creatureId: 'c1',
      heightCm: 40,
      weightKg: 12,
      eyeDescription: 'Glowing amber',
    );
    const ability = CreatureAbilityModel(
      id: 'a1',
      creatureId: 'c1',
      name: 'EMP pulse',
    );
    const mode = CreatureModeModel(
      id: 'm1',
      creatureId: 'c1',
      name: 'Combat',
      defaultMode: true,
    );

    final sheet = ProductionAssetDetailResolver.resolve(
      kind: ProductionAssetKind.creature,
      creature: creature,
      profile: profile,
      abilities: [ability],
      modes: [mode],
    );

    expect(sheet.title, 'Byte');
    expect(sheet.subtitle, 'companion');
    expect(
      sheet.sections.keys,
      containsAll(['Identity', 'Physical', 'Abilities', 'Modes']),
    );
    expect(sheet.value('Physical', 'Height'), '40.0 cm');
    expect(sheet.value('Physical', 'Weight'), '12.0 kg');
    expect(sheet.value('Abilities', 'EMP pulse'), isNotNull);
    expect(sheet.value('Modes', 'Combat'), 'default');
  });

  test('resolves vehicle detail sheet from domain models', () {
    const vehicle = VehicleModel(
      assetId: 'v1',
      projectId: 'p1',
      name: 'Neo Interceptor',
      category: VehicleCategory.spacecraft,
    );
    const spec = VehicleSpecification(
      vehicleId: 'v1',
      lengthMeters: 12.5,
      crew: 2,
    );
    const mount = VehicleWeaponMountModel(
      id: 'wm1',
      vehicleId: 'v1',
      weaponId: 'w1',
      mountName: 'Nose',
    );

    final sheet = ProductionAssetDetailResolver.resolve(
      kind: ProductionAssetKind.vehicle,
      vehicle: vehicle,
      specification: spec,
      mounts: [mount],
    );

    expect(sheet.title, 'Neo Interceptor');
    expect(sheet.subtitle, 'spacecraft');
    expect(sheet.value('Specifications', 'Length'), '12.5 m');
    expect(sheet.value('Weapons', 'Nose'), 'w1');
  });

  test('resolves prop detail sheet from domain models', () {
    const prop = PropModel(
      assetId: 'pr1',
      projectId: 'p1',
      name: 'Void Key',
      category: PropCategory.storyCritical,
      storyCritical: true,
    );
    const spec = PropSpecification(propId: 'pr1', material: 'Void alloy');
    const state = PropStateModel(id: 's1', propId: 'pr1', name: 'Inert');

    final sheet = ProductionAssetDetailResolver.resolve(
      kind: ProductionAssetKind.prop,
      prop: prop,
      propSpec: spec,
      states: [state],
    );

    expect(sheet.title, 'Void Key');
    expect(sheet.subtitle, 'storyCritical');
    expect(sheet.value('Materials', 'Material'), 'Void alloy');
    expect(sheet.value('States', 'Inert'), isNotNull);
  });
}
