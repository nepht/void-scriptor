/// Sprint 46 — Step 46.9–46.25 NPC Agents, Memory, Relationships.
enum NpcSimulationLevel { static, reactive, routine, full }

class NpcAgent {
  const NpcAgent({
    required this.id,
    required this.name,
    required this.simulationLevel,
    this.needs = const [],
    this.personality,
    this.goals = const [],
    this.routines = const [],
    this.memories = const [],
    this.relationships = const [],
  });

  final String id;
  final String name;
  final NpcSimulationLevel simulationLevel;
  final List<NpcNeed> needs;
  final NpcPersonality? personality;
  final List<NpcGoal> goals;
  final List<NpcRoutine> routines;
  final List<MemoryModel> memories;
  final List<RelationshipState> relationships;
}

class NpcNeed {
  const NpcNeed({required this.id, required this.label, required this.value});

  final String id;
  final String label;
  final double value;
}

class NpcPersonality {
  const NpcPersonality({
    this.openness = 3,
    this.conscientiousness = 3,
    this.extraversion = 3,
    this.agreeableness = 3,
    this.neuroticism = 3,
  });

  final int openness;
  final int conscientiousness;
  final int extraversion;
  final int agreeableness;
  final int neuroticism;
}

class NpcGoal {
  const NpcGoal({
    required this.id,
    required this.description,
    this.priority = 1,
    this.completed = false,
  });

  final String id;
  final String description;
  final int priority;
  final bool completed;
}

class NpcRoutine {
  const NpcRoutine({
    required this.id,
    required this.label,
    required this.startHour,
    required this.durationMinutes,
  });

  final String id;
  final String label;
  final int startHour;
  final int durationMinutes;
}

/// Step 46.18–46.21 Memory System with decay.
class MemoryModel {
  const MemoryModel({
    required this.id,
    required this.npcId,
    required this.content,
    required this.strength,
    required this.lastAccessedAt,
  });

  final String id;
  final String npcId;
  final String content;
  final double strength;
  final DateTime lastAccessedAt;

  MemoryModel decayed({required DateTime now, double halfLifeDays = 30}) {
    final daysElapsed = now.difference(lastAccessedAt).inHours / 24.0;
    final factor = 0.5 * (daysElapsed / halfLifeDays);
    final newStrength = (strength - factor).clamp(0.0, 1.0);
    return MemoryModel(
      id: id,
      npcId: npcId,
      content: content,
      strength: newStrength,
      lastAccessedAt: lastAccessedAt,
    );
  }
}

/// Step 46.22–46.24 Dynamic Relationships.
class RelationshipState {
  const RelationshipState({
    required this.id,
    required this.npcId,
    required this.otherEntityId,
    required this.value,
  });

  final String id;
  final String npcId;
  final String otherEntityId;
  final double value;
}
