import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character_mode/domain/loadout_slot.dart';
import 'package:void_scriptor/features/character_mode/presentation/widgets/character_mode_section.dart';

void main() {
  test('loadout editor exposes armor and carried-item assignments', () {
    expect(characterLoadoutEditorSlots, contains(LoadoutSlot.armor));
    expect(characterLoadoutEditorSlots, contains(LoadoutSlot.carriedItem));
    expect(
      characterLoadoutEditorSlots.indexOf(LoadoutSlot.armor),
      lessThan(characterLoadoutEditorSlots.indexOf(LoadoutSlot.primaryWeapon)),
    );
    expect(
      characterLoadoutEditorSlots.indexOf(LoadoutSlot.carriedItem),
      greaterThan(characterLoadoutEditorSlots.indexOf(LoadoutSlot.accessory)),
    );
  });
}
