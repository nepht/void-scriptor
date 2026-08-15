enum PresenceState { online, idle, offline }

class PresenceEntry {
  const PresenceEntry({
    required this.projectId,
    required this.userId,
    required this.state,
    required this.updatedAt,
  });

  final String projectId;
  final String userId;
  final PresenceState state;
  final DateTime updatedAt;
}

class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.projectId,
    required this.actorId,
    required this.kind,
    this.payload,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final String actorId;
  final String kind;
  final String? payload;
  final DateTime createdAt;
}
