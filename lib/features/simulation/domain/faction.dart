/// Sprint 46 — Step 46.26–46.32 Factions, Government, Politics.
class FactionState {
  const FactionState({
    required this.id,
    required this.worldId,
    required this.name,
    required this.influence,
    this.goals = const [],
    this.relationships = const [],
  });

  final String id;
  final String worldId;
  final String name;
  final double influence;
  final List<String> goals;
  final List<FactionRelation> relationships;
}

class FactionRelation {
  const FactionRelation({required this.factionId, required this.attitude});

  final String factionId;
  final double attitude;
}

enum GovernmentModel {
  autocracy,
  oligarchy,
  democracy,
  theocracy,
  meritocracy,
  anarchy,
}

class PoliticalEvent {
  const PoliticalEvent({
    required this.id,
    required this.settlementId,
    required this.description,
    required this.impact,
  });

  final String id;
  final String settlementId;
  final String description;
  final double impact;
}
