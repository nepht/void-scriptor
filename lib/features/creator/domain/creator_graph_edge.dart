/// Sprint 43 — Step 43.23 Creator Graph.
///
/// Production-focused relation graph (not a plain social follower graph):
/// follows, collaborates with, worked on, created, owns, contributed to.
enum CreatorGraphEdgeType {
  follows,
  collaboratesWith,
  workedOn,
  created,
  owns,
  contributedTo,
}

class CreatorGraphEdge {
  const CreatorGraphEdge({
    required this.id,
    required this.sourceCreatorId,
    required this.targetId,
    required this.type,
  });

  final String id;
  final String sourceCreatorId;
  final String targetId;
  final CreatorGraphEdgeType type;
}
