enum EntityType { character, location, item, faction, event, concept }

/// A knowledge entity in the universe ontology (Step 38.1).
class KnowledgeEntity {
  const KnowledgeEntity({
    required this.id,
    required this.type,
    required this.title,
    this.facts = const [],
  });

  final String id;
  final EntityType type;
  final String title;
  final List<String> facts;
}
