/// Sprint 47 — Step 47.76–47.79 Network Architecture, Multiplayer.
enum NetworkMode { offline, coop, versus, massive }

class NetworkEntity {
  const NetworkEntity({
    required this.id,
    required this.ownerId,
    required this.replicated,
  });

  final String id;
  final String ownerId;
  final bool replicated;
}

class ReplicationRule {
  const ReplicationRule({
    required this.entityId,
    required this.property,
    required this.intervalMs,
  });

  final String entityId;
  final String property;
  final int intervalMs;
}
