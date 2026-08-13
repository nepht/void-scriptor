class TimelineEraModel {
  const TimelineEraModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.orderIndex,
    this.description = '',
    this.startLabel,
    this.endLabel,
  });

  final String id;
  final String projectId;
  final String name;
  final String description;
  final int orderIndex;
  final String? startLabel;
  final String? endLabel;
}
