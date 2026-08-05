// World Model — v1.0.0

class World {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> geography;
  final Map<String, dynamic> rules;
  final List<String> factions;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  World({
    required this.id,
    required this.name,
    this.description = '',
    this.geography = const {},
    this.rules = const {},
    this.factions = const [],
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'geography': geography,
        'rules': rules,
        'factions': factions,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory World.fromJson(Map<String, dynamic> json) => World(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        geography: Map<String, dynamic>.from(json['geography'] as Map? ?? {}),
        rules: Map<String, dynamic>.from(json['rules'] as Map? ?? {}),
        factions: List<String>.from(json['factions'] as List? ?? []),
        tags: List<String>.from(json['tags'] as List? ?? []),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
}
