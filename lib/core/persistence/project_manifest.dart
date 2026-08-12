class ProjectManifest {
  const ProjectManifest({
    required this.schemaVersion,
    required this.id,
    required this.name,
    required this.description,
    required this.projectVersion,
    required this.createdAt,
    required this.updatedAt,
    required this.appVersion,
  });

  final int schemaVersion;
  final String id;
  final String name;
  final String description;
  final String projectVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String appVersion;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'name': name,
    'description': description,
    'projectVersion': projectVersion,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'application': {'name': 'Void Scriptor', 'version': appVersion},
  };

  factory ProjectManifest.fromJson(Map<String, dynamic> json) {
    final application =
        json['application'] as Map<String, dynamic>? ?? const {};
    return ProjectManifest(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      projectVersion:
          json['projectVersion'] as String? ??
          (json['version'] as String? ?? '0.1.0'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      appVersion: application['version'] as String? ?? 'unknown',
    );
  }
}
