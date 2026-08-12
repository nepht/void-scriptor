import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character_mode/domain/loadout_slot.dart';

void main() {
  test('every loadout slot exposes a semantic asset type', () {
    expect(LoadoutSlot.wardrobe.assetType, 'wardrobe');
    expect(LoadoutSlot.primaryWeapon.assetType, 'weapon');
    expect(LoadoutSlot.secondaryWeapon.assetType, 'weapon');
    expect(LoadoutSlot.accessory.assetType, 'accessory');
    expect(LoadoutSlot.hairVariant.assetType, 'hair_variant');
    expect(LoadoutSlot.companion.assetType, 'companion');
    expect(LoadoutSlot.vehicle.assetType, 'vehicle');
  });

  test('weapon quantity rules reject invalid dual weapon values', () {
    expect(validateLoadoutQuantity(LoadoutSlot.primaryWeapon, 1), isNull);
    expect(validateLoadoutQuantity(LoadoutSlot.primaryWeapon, 2), isNull);
    expect(validateLoadoutQuantity(LoadoutSlot.primaryWeapon, 0), isNotNull);
    expect(validateLoadoutQuantity(LoadoutSlot.accessory, 0), isNotNull);
  });
}
