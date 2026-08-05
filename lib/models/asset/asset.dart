// Asset Model — v1.0.0

class Asset {
  final String id;
  final String name;
  final String type; // image, audio, document, other
  final String path;
  final String? thumbnailPath;
  final Map<String, dynamic> metadata;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Asset({
    required this.id,
    required this.name,
    required this.type,
    required this.path,
    this.thumbnailPath,
    this.metadata = const {},
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'path': path,
        'thumbnailPath': thumbnailPath,
        'metadata': metadata,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        path: json['path'] as String,
        thumbnailPath: json['thumbnailPath'] as String?,
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
        tags: List<String>.from(json['tags'] as List? ?? []),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
}
