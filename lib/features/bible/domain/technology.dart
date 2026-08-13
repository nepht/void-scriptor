class TechnologyModel {
  const TechnologyModel({
    required this.assetId,
    required this.projectId,
    required this.name,
    this.category = '',
    this.description = '',
    this.creator = '',
    this.limitations = '',
  });

  final String assetId;
  final String projectId;
  final String name;
  final String category;
  final String description;
  final String creator;
  final String limitations;
}
