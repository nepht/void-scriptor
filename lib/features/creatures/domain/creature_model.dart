enum CreatureCategory {
  animal,
  companion,
  monster,
  dragon,
  spirit,
  synthetic,
  biological,
  hybrid,
  unknown,
}

class CreatureModel {
  const CreatureModel({
    required this.assetId,
    required this.projectId,
    required this.name,
    required this.category,
    this.speciesId,
    this.description = '',
    this.behavior = '',
    this.abilities = '',
    this.origin = '',
  });

  final String assetId;
  final String projectId;
  final String name;
  final CreatureCategory category;
  final String? speciesId;
  final String description;
  final String behavior;
  final String abilities;
  final String origin;
}

class CreaturePhysicalProfile {
  const CreaturePhysicalProfile({
    required this.creatureId,
    this.heightCm,
    this.lengthCm,
    this.weightKg,
    this.bodyStructure = '',
    this.skinMaterial = '',
    this.eyeDescription = '',
    this.distinguishingFeatures = '',
  });

  final String creatureId;
  final double? heightCm;
  final double? lengthCm;
  final double? weightKg;
  final String bodyStructure;
  final String skinMaterial;
  final String eyeDescription;
  final String distinguishingFeatures;
}

class CreatureAbilityModel {
  const CreatureAbilityModel({
    required this.id,
    required this.creatureId,
    required this.name,
    this.description = '',
    this.powerSystemId,
    this.sortOrder = 0,
  });

  final String id;
  final String creatureId;
  final String name;
  final String description;
  final String? powerSystemId;
  final int sortOrder;
}

class CreatureModeModel {
  const CreatureModeModel({
    required this.id,
    required this.creatureId,
    required this.name,
    this.description = '',
    this.referenceSetId,
    this.defaultMode = false,
  });

  final String id;
  final String creatureId;
  final String name;
  final String description;
  final String? referenceSetId;
  final bool defaultMode;

  CreatureModeModel copyWith({String? creatureId}) => CreatureModeModel(
    id: id,
    creatureId: creatureId ?? this.creatureId,
    name: name,
    description: description,
    referenceSetId: referenceSetId,
    defaultMode: defaultMode,
  );
}
