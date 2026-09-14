/// Resolved child-record view data for the Weapon workspace.
///
/// vs-hunt-20260914-wardrobe-weapon WBUG-6: the detail cards previously
/// rendered const sample chips and fixed dimension/energy rows regardless
/// of what the project database stored. These models carry the persisted
/// rows (via [WeaponRepository.getWorkspaceData]) so the cards are
/// data-driven, following the ENV-BUG-002 precedent (run271).
class WeaponComponentInfo {
  const WeaponComponentInfo({required this.name, required this.componentType});

  final String name;
  final String componentType;
}

class WeaponMeasurementInfo {
  const WeaponMeasurementInfo({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final double value;
  final String unit;
}

class WeaponEnergyInfo {
  const WeaponEnergyInfo({
    this.activation = '',
    this.emissionColor = '',
    this.behavior = '',
  });

  final String activation;
  final String emissionColor;
  final String behavior;
}

class WeaponVariantInfo {
  const WeaponVariantInfo({required this.name, this.isDefault = false});

  final String name;
  final bool isDefault;
}

class WeaponReferenceInfo {
  const WeaponReferenceInfo({required this.referenceType, this.filePath = ''});

  final String referenceType;
  final String filePath;
}

class WeaponWorkspaceData {
  const WeaponWorkspaceData({
    this.components = const [],
    this.measurements = const [],
    this.energy,
    this.variants = const [],
    this.references = const [],
  });

  final List<WeaponComponentInfo> components;
  final List<WeaponMeasurementInfo> measurements;
  final WeaponEnergyInfo? energy;
  final List<WeaponVariantInfo> variants;
  final List<WeaponReferenceInfo> references;
}
