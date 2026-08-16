/// A directed relation between two entities (Step 38.2).
class EntityRelation {
  const EntityRelation({
    required this.sourceId,
    required this.targetId,
    required this.kind,
  });

  final String sourceId;
  final String targetId;
  final String kind;
}
