class TimelineEraModel {
  const TimelineEraModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.orderIndex,
    this.description = '',
    this.startLabel,
    this.endLabel,
    this.imagePath = '',
  });

  final String id;
  final String projectId;
  final String name;
  final String description;
  final int orderIndex;
  final String? startLabel;
  final String? endLabel;

  /// run236: package-owned reference image for the era (worldbuilding/timeline
  /// visual parity). Unlike factions/locations an era is NOT an `assets` row,
  /// so it carries its own column; empty means no image bound yet.
  final String imagePath;

  TimelineEraModel copyWith({String? imagePath}) => TimelineEraModel(
    id: id,
    projectId: projectId,
    name: name,
    description: description,
    orderIndex: orderIndex,
    startLabel: startLabel,
    endLabel: endLabel,
    imagePath: imagePath ?? this.imagePath,
  );
}
