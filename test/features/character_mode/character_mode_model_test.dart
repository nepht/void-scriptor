import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character_mode/domain/character_mode.dart';
import 'package:void_scriptor/features/character_mode/domain/loadout_slot.dart';
import 'package:void_scriptor/features/character_mode/domain/effective_identity_profile.dart';
import 'package:void_scriptor/features/character/domain/character_identity_profile.dart';

void main() {
  test('character mode stores identity and optional thumbnail', () {
    const mode = CharacterMode(
      id: 'mode-1',
      projectId: 'project-1',
      characterId: 'character-1',
      name: 'Combat Mode',
      thumbnailPath: 'thumbs/combat.png',
    );

    expect(mode.name, 'Combat Mode');
    expect(mode.isDefault, isFalse);
    expect(mode.thumbnailPath, 'thumbs/combat.png');
  });

  test('loadout slots serialize to stable database values', () {
    expect(LoadoutSlot.wardrobe.value, 'wardrobe');
    expect(LoadoutSlot.primaryWeapon.value, 'primary_weapon');
    expect(LoadoutSlot.secondaryWeapon.value, 'secondary_weapon');
    expect(LoadoutSlot.accessory.value, 'accessory');
  });

  test('single slots reject multiple entries while accessories allow many', () {
    expect(
      LoadoutSlot.primaryWeapon.multiplicity,
      LoadoutSlotMultiplicity.single,
    );
    expect(
      LoadoutSlot.accessory.multiplicity,
      LoadoutSlotMultiplicity.multiple,
    );
  });

  test('effective identity inherits nullable mode overrides', () {
    const base = CharacterIdentityProfile(
      characterId: 'character-1',
      faceLock: true,
      hairLock: true,
      bodyLock: true,
      colorLock: true,
      outfitLock: false,
    );
    const override = CharacterModeIdentityOverride(
      modeId: 'mode-1',
      hairLock: false,
      outfitLock: true,
      weaponLock: true,
    );

    final effective = resolveEffectiveIdentity(base: base, override: override);

    expect(effective.faceLock, isTrue);
    expect(effective.hairLock, isFalse);
    expect(effective.bodyLock, isTrue);
    expect(effective.outfitLock, isTrue);
    expect(effective.weaponLock, isTrue);
  });
}
