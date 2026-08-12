class WardrobeModel {
  const WardrobeModel({
    required this.assetId,
    required this.projectId,
    required this.name,
    this.category = '',
    this.description = '',
    this.primaryMaterial = '',
    this.fabric = '',
    this.fit = '',
    this.style = '',
    this.notes = '',
  });

  final String assetId;
  final String projectId;
  final String name;
  final String category;
  final String description;
  final String primaryMaterial;
  final String fabric;
  final String fit;
  final String style;
  final String notes;
}
