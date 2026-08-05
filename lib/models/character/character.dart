// Character Model — v1.0.0

class Character {
  final String id;
  final String name;
  final String description;
  final String backstory;
  final Map<String, dynamic> attributes;
  final List<String> relationships;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Character({
    required this.id,
    required this.name,
    this.description = '',
    this.backstory = '',
    this.attributes = const {},
    this.relationships = const [],
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'backstory': backstory,
        'attributes': attributes,
        'relationships': relationships,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Character.fromJson(Map<String, dynamic> json) => Character(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        backstory: json['backstory'] as String? ?? '',
        attributes: Map<String, dynamic>.from(json['attributes'] as Map? ?? {}),
        relationships: List<String>.from(json['relationships'] as List? ?? []),
        tags: List<String>.from(json['tags'] as List? ?? []),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );

  Character copyWith({
    String? name,
    String? description,
    String? backstory,
    Map<String, dynamic>? attributes,
    List<String>? relationships,
    List<String>? tags,
  }) {
    return Character(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      backstory: backstory ?? this.backstory,
      attributes: attributes ?? this.attributes,
      relationships: relationships ?? this.relationships,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
