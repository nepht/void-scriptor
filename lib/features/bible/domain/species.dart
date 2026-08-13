class SpeciesModel {
  const SpeciesModel({
    required this.assetId,
    required this.projectId,
    required this.name,
    this.origin = '',
    this.description = '',
    this.lifespan = '',
    this.traits = '',
  });

  final String assetId;
  final String projectId;
  final String name;
  final String origin;
  final String description;
  final String lifespan;
  final String traits;
}
