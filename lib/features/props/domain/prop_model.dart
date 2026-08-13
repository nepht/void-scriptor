enum PropCategory {
  handheld,
  furniture,
  technology,
  container,
  document,
  decoration,
  food,
  tool,
  device,
  interactive,
  background,
  storyCritical,
  other,
}

class PropModel {
  const PropModel({
    required this.assetId,
    required this.projectId,
    required this.name,
    required this.category,
    this.description = '',
    this.function = '',
    this.storyCritical = false,
  });
  final String assetId, projectId, name, description, function;
  final PropCategory category;
  final bool storyCritical;
}

class PropSpecification {
  const PropSpecification({
    required this.propId,
    this.widthCm,
    this.heightCm,
    this.depthCm,
    this.weightKg,
    this.material = '',
    this.color = '',
  });
  final String propId, material, color;
  final double? widthCm, heightCm, depthCm, weightKg;
}

class PropStateModel {
  const PropStateModel({
    required this.id,
    required this.propId,
    required this.name,
    this.description = '',
    this.referenceSetId,
    this.sortOrder = 0,
  });
  final String id, propId, name, description;
  final String? referenceSetId;
  final int sortOrder;
}
