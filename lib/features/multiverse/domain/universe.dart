/// Sprint 45 — Step 45.1–45.7 Universe Registry, Identity, Types, Canon Isolation.
enum UniverseType {
  canon,
  alternate,
  whatIf,
  spinOff,
  au,
  crossover,
  parallel,
  dream,
}

class Universe {
  Universe({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.isPrimary = false,
    this.timelineIds = const [],
    this.characterIds = const [],
    this.createdAt,
  });

  final String id;
  final String name;
  final UniverseType type;
  final String? description;
  bool isPrimary;
  final List<String> timelineIds;
  final List<String> characterIds;
  final DateTime? createdAt;

  Universe copyWith({
    String? name,
    UniverseType? type,
    String? description,
    bool? isPrimary,
    List<String>? timelineIds,
    List<String>? characterIds,
  }) {
    return Universe(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      isPrimary: isPrimary ?? this.isPrimary,
      timelineIds: timelineIds ?? this.timelineIds,
      characterIds: characterIds ?? this.characterIds,
      createdAt: createdAt,
    );
  }
}

/// Step 45.6 Universe Context.
class UniverseContext {
  const UniverseContext({
    required this.activeUniverseId,
    this.previousUniverseId,
  });

  final String activeUniverseId;
  final String? previousUniverseId;
}

/// Step 45.5 Canon Isolation Layer.
class CanonIsolationConfig {
  const CanonIsolationConfig({
    required this.universeId,
    this.isolateCharacters = true,
    this.isolateTimelines = true,
    this.isolateBible = true,
  });

  final String universeId;
  final bool isolateCharacters;
  final bool isolateTimelines;
  final bool isolateBible;
}
