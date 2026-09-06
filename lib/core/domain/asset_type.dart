/// Core-owned asset type enumeration (ADR-0001).
///
/// Moved from `features/assets/domain/asset_type.dart` so Core selection
/// state does not depend on the Assets feature. The old path remains a
/// compatibility export.
enum AssetType {
  character,
  wardrobe,
  weapon,
  armor,
  accessory,
  creature,
  vehicle,
  prop,
  vfx,
  soundEffect,
  ambience,
  music,
  environment,
  story,
  scene,
  timeline,
  prompt,
  aiGeneration,
  reference,
  faction,
  species,
  technology,
  powerSystem,
}
