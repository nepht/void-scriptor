/// Sprint 47 — Step 47.8–47.10 Level system.
class Level {
  const Level({
    required this.id,
    required this.gameProjectId,
    required this.name,
    required this.order,
    this.streamingEnabled = false,
    this.spawnPoints = const [],
  });

  final String id;
  final String gameProjectId;
  final String name;
  final int order;
  final bool streamingEnabled;
  final List<SpawnPoint> spawnPoints;
}

class SpawnPoint {
  const SpawnPoint({
    required this.id,
    required this.x,
    required this.y,
    required this.z,
  });

  final String id;
  final double x;
  final double y;
  final double z;
}
