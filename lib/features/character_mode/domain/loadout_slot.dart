enum LoadoutSlot {
  wardrobe,
  armor,
  primaryWeapon,
  secondaryWeapon,
  accessory,
  carriedItem,
  hairVariant,
  companion,
  vehicle,
}

enum LoadoutSlotMultiplicity { single, multiple }

extension LoadoutSlotValue on LoadoutSlot {
  String get value => switch (this) {
    LoadoutSlot.wardrobe => 'wardrobe',
    LoadoutSlot.armor => 'armor',
    LoadoutSlot.primaryWeapon => 'primary_weapon',
    LoadoutSlot.secondaryWeapon => 'secondary_weapon',
    LoadoutSlot.accessory => 'accessory',
    LoadoutSlot.carriedItem => 'carried_item',
    LoadoutSlot.hairVariant => 'hair_variant',
    LoadoutSlot.companion => 'companion',
    LoadoutSlot.vehicle => 'vehicle',
  };

  String get assetType => switch (this) {
    LoadoutSlot.wardrobe => 'wardrobe',
    LoadoutSlot.armor => 'armor',
    LoadoutSlot.primaryWeapon || LoadoutSlot.secondaryWeapon => 'weapon',
    LoadoutSlot.accessory => 'accessory',
    LoadoutSlot.carriedItem => 'prop',
    LoadoutSlot.hairVariant => 'hair_variant',
    // Product decision (Choirudin, 2026-09-06): a companion is a creature.
    LoadoutSlot.companion => 'creature',
    LoadoutSlot.vehicle => 'vehicle',
  };

  LoadoutSlotMultiplicity get multiplicity =>
      this == LoadoutSlot.accessory || this == LoadoutSlot.carriedItem
      ? LoadoutSlotMultiplicity.multiple
      : LoadoutSlotMultiplicity.single;
}

extension LoadoutSlotParsing on String {
  LoadoutSlot? get loadoutSlot => switch (this) {
    'wardrobe' => LoadoutSlot.wardrobe,
    'armor' => LoadoutSlot.armor,
    'primary_weapon' => LoadoutSlot.primaryWeapon,
    'secondary_weapon' => LoadoutSlot.secondaryWeapon,
    'accessory' => LoadoutSlot.accessory,
    'carried_item' => LoadoutSlot.carriedItem,
    'hair_variant' => LoadoutSlot.hairVariant,
    'companion' => LoadoutSlot.companion,
    'vehicle' => LoadoutSlot.vehicle,
    _ => null,
  };
}

String? validateLoadoutQuantity(LoadoutSlot slot, int quantity) {
  if (quantity < 1) return 'Quantity must be at least 1';
  final supportsQuantity =
      slot == LoadoutSlot.primaryWeapon ||
      slot == LoadoutSlot.secondaryWeapon ||
      slot == LoadoutSlot.carriedItem;
  if (!supportsQuantity && quantity != 1) {
    return '${slot.value} supports quantity 1 only';
  }
  return null;
}
