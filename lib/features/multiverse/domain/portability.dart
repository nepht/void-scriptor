/// Sprint 45 — Step 45.19–45.30 Character Portability, Variants, Asset Portability.
class CharacterVariant {
  const CharacterVariant({
    required this.id,
    required this.characterId,
    required this.universeId,
    required this.variantName,
    this.identityLocked = false,
    this.sourceVariantId,
  });

  final String id;
  final String characterId;
  final String universeId;
  final String variantName;
  final bool identityLocked;
  final String? sourceVariantId;

  bool get isCanonVariant => identityLocked;
}

/// Step 45.21 Port Modes.
enum PortMode { reference, clone, variant, lockedIdentity }

/// Step 45.27 Asset Link.
class AssetLink {
  const AssetLink({
    required this.id,
    required this.assetId,
    required this.sourceUniverseId,
    required this.targetUniverseId,
  });

  final String id;
  final String assetId;
  final String sourceUniverseId;
  final String targetUniverseId;
}

/// Step 45.28 Asset Snapshot.
class AssetSnapshot {
  const AssetSnapshot({
    required this.id,
    required this.assetId,
    required this.universeId,
    required this.contentHash,
    required this.capturedAt,
  });

  final String id;
  final String assetId;
  final String universeId;
  final String contentHash;
  final DateTime capturedAt;
}

/// Step 45.29 Asset Dependency Graph.
class AssetDependency {
  const AssetDependency({
    required this.assetId,
    required this.dependsOnAssetId,
    this.required = true,
  });

  final String assetId;
  final String dependsOnAssetId;
  final bool required;
}

/// Step 45.25 Variant Lock Matrix.
class VariantLockMatrix {
  const VariantLockMatrix({
    required this.characterId,
    required this.lockedVariantIds,
  });

  final String characterId;
  final List<String> lockedVariantIds;
}
