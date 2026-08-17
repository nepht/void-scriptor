/// Sprint 47 — Step 47.37–47.43 Enemy AI, Boss Framework.
enum EnemyAiState { idle, patrol, chase, attack, flee, stunned, dead }

class EnemyAI {
  const EnemyAI({
    required this.id,
    required this.entityId,
    required this.visionRange,
    required this.hearingRange,
    this.state = EnemyAiState.idle,
  });

  final String id;
  final String entityId;
  final double visionRange;
  final double hearingRange;
  final EnemyAiState state;
}

class BossPhase {
  const BossPhase({
    required this.id,
    required this.name,
    required this.healthThreshold,
    required this.abilities,
  });

  final String id;
  final String name;
  final double healthThreshold;
  final List<String> abilities;
}
