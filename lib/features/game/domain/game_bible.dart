/// Sprint 47 — Step 47.109–47.112 Game Bible, Gameplay Locks, Core Loop.
class GameBible {
  const GameBible({
    required this.id,
    required this.projectId,
    this.entries = const [],
  });

  final String id;
  final String projectId;
  final List<GameBibleEntry> entries;
}

class GameBibleEntry {
  const GameBibleEntry({
    required this.id,
    required this.title,
    required this.content,
  });

  final String id;
  final String title;
  final String content;
}

class GameplayLock {
  const GameplayLock({
    required this.id,
    required this.entityId,
    required this.feature,
    required this.locked,
  });

  final String id;
  final String entityId;
  final String feature;
  final bool locked;
}

enum CoreLoopStep { explore, encounter, combat, reward, progress }
