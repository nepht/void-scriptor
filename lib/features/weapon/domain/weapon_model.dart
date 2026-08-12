class WeaponModel {
  const WeaponModel({
    required this.assetId,
    required this.projectId,
    required this.name,
    this.weaponType = '',
    this.description = '',
    this.primaryMaterial = '',
    this.secondaryMaterial = '',
    this.energyType = '',
    this.coreType = '',
    this.lengthMm,
    this.weightKg,
    this.notes = '',
  });

  final String assetId;
  final String projectId;
  final String name;
  final String weaponType;
  final String description;
  final String primaryMaterial;
  final String secondaryMaterial;
  final String energyType;
  final String coreType;
  final double? lengthMm;
  final double? weightKg;
  final String notes;
}
