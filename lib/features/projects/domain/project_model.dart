class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.lastOpenedAt,
    required this.localPath,
    required this.version,
    this.thumbnailPath,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastOpenedAt;
  final String localPath;
  final String version;
  final String? thumbnailPath;
  final List<String> tags;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lastOpenedAt': lastOpenedAt.toIso8601String(),
    'localPath': localPath,
    'version': version,
    'thumbnailPath': thumbnailPath,
    'tags': tags,
  };

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    lastOpenedAt: DateTime.parse(json['lastOpenedAt'] as String),
    localPath: json['localPath'] as String,
    version: json['version'] as String? ?? '0.1.0',
    thumbnailPath: json['thumbnailPath'] as String?,
    tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
  );

  ProjectModel copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastOpenedAt,
    String? localPath,
    String? version,
    String? thumbnailPath,
    List<String>? tags,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      localPath: localPath ?? this.localPath,
      version: version ?? this.version,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectModel &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.lastOpenedAt == lastOpenedAt &&
          other.localPath == localPath &&
          other.version == version &&
          other.thumbnailPath == thumbnailPath &&
          _listEquals(other.tags, tags);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    createdAt,
    updatedAt,
    lastOpenedAt,
    localPath,
    version,
    thumbnailPath,
    Object.hashAll(tags),
  );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
