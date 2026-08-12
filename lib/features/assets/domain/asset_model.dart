import 'asset_type.dart';

class AssetModel {
  const AssetModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.type,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.thumbnailPath,
    this.tags = const [],
  });

  final String id;
  final String projectId;
  final String name;
  final String description;
  final AssetType type;
  final String version;
  final String? thumbnailPath;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  AssetModel copyWith({
    String? name,
    String? description,
    String? version,
    String? thumbnailPath,
    List<String>? tags,
    DateTime? updatedAt,
  }) => AssetModel(
    id: id,
    projectId: projectId,
    name: name ?? this.name,
    description: description ?? this.description,
    type: type,
    version: version ?? this.version,
    thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    tags: tags ?? this.tags,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
