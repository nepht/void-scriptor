import '../project_package/void_project_format.dart';

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
    this.databaseFilename = 'database/project.db',
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
    'format': VoidProjectFormat.name,
    'schemaVersion': schemaVersion,
    'projectId': id,
    'name': name,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'application': {'name': 'Void Scriptor Studio', 'version': appVersion},
    'database': {'file': databaseFilename},
    'assets': {'root': 'assets'},
    'projectVersion': projectVersion,
    'tags': tags,
  };

  factory ProjectManifest.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'] as int? ?? 1;
    if (schemaVersion > VoidProjectFormat.currentSchema) {
      throw FormatException(
        'Unsupported project manifest schema version: $schemaVersion',
      );
    }
    final application =
        (json['application'] as Map<String, dynamic>?) ?? const {};
    final database = json['database'];
    final databaseFilename = database is Map<String, dynamic>
        ? database['file'] as String? ?? 'database/project.db'
        : database as String? ?? 'project.db';
    return ProjectManifest(
      schemaVersion: schemaVersion,
      id: (json['projectId'] ?? json['id']) as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      projectVersion:
          json['projectVersion'] as String? ??
          (json['version'] as String? ?? '0.1.0'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      appVersion: application['version'] as String? ?? 'unknown',
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
      databaseFilename: databaseFilename,
    );
  }
}
