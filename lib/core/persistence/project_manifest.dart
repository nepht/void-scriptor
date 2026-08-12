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
    this.tags = const [],
    this.databaseFilename = 'project.db',
  });

  final int schemaVersion;
  final String id;
  final String name;
  final String description;
  final String projectVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String appVersion;
  final List<String> tags;
  final String databaseFilename;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'name': name,
    'description': description,
    'projectVersion': projectVersion,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'application': {'name': 'Void Scriptor', 'version': appVersion},
    'tags': tags,
    'database': databaseFilename,
  };

  factory ProjectManifest.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'] as int? ?? 1;
    if (schemaVersion != 1) {
      throw FormatException(
        'Unsupported project manifest schema version: $schemaVersion',
      );
    }
    final application =
        json['application'] as Map<String, dynamic>? ?? const {};
    return ProjectManifest(
      schemaVersion: schemaVersion,
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      projectVersion:
          json['projectVersion'] as String? ??
          (json['version'] as String? ?? '0.1.0'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      appVersion: application['version'] as String? ?? 'unknown',
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
      databaseFilename: json['database'] as String? ?? 'project.db',
    );
  }
}
