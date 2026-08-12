class CharacterMode {
  const CharacterMode({
    required this.id,
    required this.projectId,
    required this.characterId,
    required this.name,
    this.description = '',
    this.isDefault = false,
    this.thumbnailPath,
    this.accentColor,
    this.tags = const [],
  });

  final String id;
  final String projectId;
  final String characterId;
  final String name;
  final String description;
  final bool isDefault;
  final String? thumbnailPath;
  final String? accentColor;
  final List<String> tags;

  CharacterMode copyWith({
    String? name,
    String? description,
    bool? isDefault,
    String? thumbnailPath,
    String? accentColor,
    List<String>? tags,
  }) => CharacterMode(
    id: id,
    projectId: projectId,
    characterId: characterId,
    name: name ?? this.name,
    description: description ?? this.description,
    isDefault: isDefault ?? this.isDefault,
    thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    accentColor: accentColor ?? this.accentColor,
    tags: tags ?? this.tags,
  );
}
