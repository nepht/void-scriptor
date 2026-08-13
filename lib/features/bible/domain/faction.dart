class FactionModel {
  const FactionModel({
    required this.assetId,
    required this.projectId,
    required this.name,
    this.description = '',
    this.ideology = '',
    this.status = '',
    this.headquarters = '',
  });

  final String assetId;
  final String projectId;
  final String name;
  final String description;
  final String ideology;
  final String status;
  final String headquarters;
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
