import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character_mode/domain/loadout_slot.dart';

void main() {
  group('character-owned loadout slots', () {
    test('armor is a distinct single-value slot', () {
      expect(LoadoutSlot.armor.value, 'armor');
      expect(LoadoutSlot.armor.assetType, 'armor');
      expect(LoadoutSlot.armor.multiplicity, LoadoutSlotMultiplicity.single);
      expect('armor'.loadoutSlot, LoadoutSlot.armor);
    });

    test('carried items allow multiple stand-alone assets', () {
      expect(LoadoutSlot.carriedItem.value, 'carried_item');
      expect(LoadoutSlot.carriedItem.assetType, 'prop');
      expect(
        LoadoutSlot.carriedItem.multiplicity,
        LoadoutSlotMultiplicity.multiple,
      );
      expect('carried_item'.loadoutSlot, LoadoutSlot.carriedItem);
      expect(validateLoadoutQuantity(LoadoutSlot.carriedItem, 3), isNull);
    });
  });
}
