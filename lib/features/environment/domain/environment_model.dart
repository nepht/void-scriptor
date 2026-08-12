class EnvironmentModel {
  const EnvironmentModel({
    required this.assetId,
    required this.projectId,
    required this.name,
    this.environmentType = '',
    this.description = '',
    this.location = '',
    this.architecture = '',
    this.terrain = '',
    this.notes = '',
  });

  final String assetId;
  final String projectId;
  final String name;
  final String environmentType;
  final String description;
  final String location;
  final String architecture;
  final String terrain;
  final String notes;
}
