/// Sprint 47 — Step 47.1–47.4 Game Project, Genre, Template.
enum GameGenre {
  action,
  actionAdventure,
  rpg,
  puzzle,
  simulation,
  strategy,
  horror,
  platformer,
  shooter,
}

enum GameTemplate {
  blank,
  thirdPersonAction,
  firstPerson,
  topDownRpg,
  platformer,
  visualNovel,
}

class GameProject {
  GameProject({
    required this.id,
    required this.name,
    required this.genre,
    required this.template,
    this.description,
    this.levels = const [],
    this.createdAt,
  });

  final String id;
  final String name;
  final GameGenre genre;
  final GameTemplate template;
  final String? description;
  final List<String> levels;
  final DateTime? createdAt;

  GameProject copyWith({
    String? name,
    GameGenre? genre,
    GameTemplate? template,
    String? description,
    List<String>? levels,
  }) {
    return GameProject(
      id: id,
      name: name ?? this.name,
      genre: genre ?? this.genre,
      template: template ?? this.template,
      description: description ?? this.description,
      levels: levels ?? this.levels,
      createdAt: createdAt,
    );
  }
}
