import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/weapon/domain/weapon_model.dart';

void main() {
  test('WeaponModel preserves technical identity and specifications', () {
    const weapon = WeaponModel(
      assetId: 'weapon-1',
      projectId: 'project-1',
      name: 'Void Dual Dagger',
      weaponType: 'Dual Dagger',
      description: 'Twin blades for close combat.',
      primaryMaterial: 'Void Alloy',
      secondaryMaterial: 'Carbon Composite',
      energyType: 'Void Energy',
      coreType: 'Crystalline Void Core',
      lengthMm: 420,
      weightKg: 0.82,
      notes: 'Quantity two.',
    );

    expect(weapon.assetId, 'weapon-1');
    expect(weapon.projectId, 'project-1');
    expect(weapon.name, 'Void Dual Dagger');
    expect(weapon.weaponType, 'Dual Dagger');
    expect(weapon.primaryMaterial, 'Void Alloy');
    expect(weapon.secondaryMaterial, 'Carbon Composite');
    expect(weapon.energyType, 'Void Energy');
    expect(weapon.coreType, 'Crystalline Void Core');
    expect(weapon.lengthMm, 420);
    expect(weapon.weightKg, 0.82);
    expect(weapon.notes, 'Quantity two.');
  });
}
