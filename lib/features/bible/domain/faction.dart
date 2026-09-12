class FactionModel {
  const FactionModel({
    required this.assetId,
    required this.projectId,
    required this.name,
    this.description = '',
    this.ideology = '',
    this.status = '',
    this.headquarters = '',
    this.imagePath = '',
  });

  final String assetId;
  final String projectId;
  final String name;
  final String description;
  final String ideology;
  final String status;
  final String headquarters;

  /// run236: package-owned reference image for the faction. Factions are
  /// NOT `assets` rows (CreateFactionService only writes the Factions
  /// table), so the image lives in its own column, not `assets.thumbnail_path`.
  final String imagePath;

  FactionModel copyWith({String? imagePath}) => FactionModel(
    assetId: assetId,
    projectId: projectId,
    name: name,
    description: description,
    ideology: ideology,
    status: status,
    headquarters: headquarters,
    imagePath: imagePath ?? this.imagePath,
  );
}

class FactionUnitModel {
  const FactionUnitModel({
    required this.id,
    required this.factionId,
    required this.name,
    this.parentUnitId,
    this.description = '',
  });

  final String id;
  final String factionId;
  final String? parentUnitId;
  final String name;
  final String description;
}
