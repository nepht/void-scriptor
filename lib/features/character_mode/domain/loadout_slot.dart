enum LoadoutSlot {
  wardrobe,
  primaryWeapon,
  secondaryWeapon,
  accessory,
  hairVariant,
  companion,
  vehicle,
}

enum LoadoutSlotMultiplicity { single, multiple }

extension LoadoutSlotValue on LoadoutSlot {
  String get value => switch (this) {
    LoadoutSlot.wardrobe => 'wardrobe',
    LoadoutSlot.primaryWeapon => 'primary_weapon',
    LoadoutSlot.secondaryWeapon => 'secondary_weapon',
    LoadoutSlot.accessory => 'accessory',
    LoadoutSlot.hairVariant => 'hair_variant',
    LoadoutSlot.companion => 'companion',
    LoadoutSlot.vehicle => 'vehicle',
  };

  String get assetType => switch (this) {
    LoadoutSlot.wardrobe => 'wardrobe',
    LoadoutSlot.primaryWeapon || LoadoutSlot.secondaryWeapon => 'weapon',
    LoadoutSlot.accessory => 'accessory',
    LoadoutSlot.hairVariant => 'hair_variant',
    LoadoutSlot.companion => 'companion',
    LoadoutSlot.vehicle => 'vehicle',
  };

  LoadoutSlotMultiplicity get multiplicity => this == LoadoutSlot.accessory
      ? LoadoutSlotMultiplicity.multiple
      : LoadoutSlotMultiplicity.single;
}

extension LoadoutSlotParsing on String {
  LoadoutSlot? get loadoutSlot => switch (this) {
    'wardrobe' => LoadoutSlot.wardrobe,
    'primary_weapon' => LoadoutSlot.primaryWeapon,
    'secondary_weapon' => LoadoutSlot.secondaryWeapon,
    'accessory' => LoadoutSlot.accessory,
    'hair_variant' => LoadoutSlot.hairVariant,
    'companion' => LoadoutSlot.companion,
    'vehicle' => LoadoutSlot.vehicle,
    _ => null,
  };
}

String? validateLoadoutQuantity(LoadoutSlot slot, int quantity) {
  if (quantity < 1) return 'Quantity must be at least 1';
  if (slot != LoadoutSlot.primaryWeapon &&
      slot != LoadoutSlot.secondaryWeapon &&
      quantity != 1) {
    return '${slot.value} supports quantity 1 only';
  }
  return null;
}
