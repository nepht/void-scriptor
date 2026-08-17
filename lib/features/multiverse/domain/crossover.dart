/// Sprint 45 — Step 45.32–45.42 Universe Bridge, Crossover, Canon Status.
class UniverseBridge {
  const UniverseBridge({
    required this.id,
    required this.fromUniverseId,
    required this.toUniverseId,
    this.rules = const [],
  });

  final String id;
  final String fromUniverseId;
  final String toUniverseId;
  final List<BridgeRule> rules;
}

class BridgeRule {
  const BridgeRule({required this.ruleId, required this.description});

  final String ruleId;
  final String description;
}

class CrossoverEvent {
  const CrossoverEvent({
    required this.id,
    required this.projectId,
    required this.universeIds,
    required this.occurredAt,
    required this.description,
  });

  final String id;
  final String projectId;
  final List<String> universeIds;
  final DateTime occurredAt;
  final String description;
}

class CrossoverStatePackage {
  const CrossoverStatePackage({
    required this.id,
    required this.entityId,
    required this.originUniverseId,
    this.stateData = const {},
  });

  final String id;
  final String entityId;
  final String originUniverseId;
  final Map<String, Object> stateData;
}

enum CanonStatus { canon, softCanon, semiCanon, nonCanon }

/// Step 45.41–45.43 Shared Lore Registry.
class LoreEntry {
  const LoreEntry({
    required this.id,
    required this.title,
    required this.content,
    this.scope = LoreScope.global,
    this.universeIds = const [],
    this.canonStatus = CanonStatus.canon,
  });

  final String id;
  final String title;
  final String content;
  final LoreScope scope;
  final List<String> universeIds;
  final CanonStatus canonStatus;
}

enum LoreScope { universe, shared, global }

/// Step 45.49–45.52 Canon Conflict Engine.
enum ConflictSeverity { info, warning, major, critical }

class CanonConflict {
  const CanonConflict({
    required this.id,
    required this.severity,
    required this.description,
    this.universeA,
    this.universeB,
    this.entityId,
  });

  final String id;
  final ConflictSeverity severity;
  final String description;
  final String? universeA;
  final String? universeB;
  final String? entityId;
}

class CanonOverride {
  const CanonOverride({
    required this.id,
    required this.conflictId,
    required this.resolution,
  });

  final String id;
  final String conflictId;
  final String resolution;
}
