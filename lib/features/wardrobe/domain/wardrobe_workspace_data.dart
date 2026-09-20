/// Resolved child-record view data for the Wardrobe workspace.
///
/// vs-hunt-20260914-wardrobe-weapon WBUG-5: the detail cards previously
/// rendered const sample chips regardless of what the project database
/// stored. These models carry the persisted rows (via
/// [WardrobeRepository.getWorkspaceData]) so the cards are data-driven,
/// following the ENV-BUG-002 precedent (run271).
class WardrobeComponentInfo {
  const WardrobeComponentInfo({
    required this.name,
    required this.componentType,
    this.material = '',
    this.fabric = '',
  });

  final String name;
  final String componentType;
  final String material;
  final String fabric;
}

class WardrobeColorInfo {
  const WardrobeColorInfo({
    required this.name,
    required this.hexValue,
    this.usage = '',
  });

  final String name;
  final String hexValue;
  final String usage;
}

class WardrobeVariantInfo {
  const WardrobeVariantInfo({required this.name, this.isDefault = false});

  final String name;
  final bool isDefault;
}

class WardrobeReferenceInfo {
  const WardrobeReferenceInfo({
    required this.referenceType,
    this.filePath = '',
  });

  final String referenceType;
  final String filePath;
}

class WardrobeWorkspaceData {
  const WardrobeWorkspaceData({
    this.components = const [],
    this.colors = const [],
    this.variants = const [],
    this.references = const [],
  });

  final List<WardrobeComponentInfo> components;
  final List<WardrobeColorInfo> colors;
  final List<WardrobeVariantInfo> variants;
  final List<WardrobeReferenceInfo> references;
}
