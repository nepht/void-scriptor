/// Sprint 45 — Step 45.12–45.18 Timeline Registry, Branch, Divergence, Temporal State.
class Timeline {
  Timeline({
    required this.id,
    required this.universeId,
    required this.name,
    this.branchOf,
    this.createdAt,
  });

  final String id;
  final String universeId;
  final String name;
  final String? branchOf;
  final DateTime? createdAt;

  bool get isAlternate => branchOf != null;

  Timeline copyWith({String? name, String? branchOf}) {
    return Timeline(
      id: id,
      universeId: universeId,
      name: name ?? this.name,
      branchOf: branchOf ?? this.branchOf,
      createdAt: createdAt,
    );
  }
}

/// Step 45.14 Divergence Event.
class DivergenceEvent {
  const DivergenceEvent({
    required this.id,
    required this.timelineId,
    required this.sourceTimelineId,
    required this.description,
    required this.atChapterSceneId,
  });

  final String id;
  final String timelineId;
  final String sourceTimelineId;
  final String description;
  final String atChapterSceneId;
}

/// Step 45.18 Temporal State System.
class TemporalState {
  const TemporalState({
    required this.id,
    required this.timelineId,
    required this.entityId,
    required this.timestamp,
    this.stateData = const {},
  });

  final String id;
  final String timelineId;
  final String entityId;
  final DateTime timestamp;
  final Map<String, Object> stateData;
}

/// Step 45.17 Timeline Diff Engine.
enum TimelineDiffKind { added, removed, changed }

class TimelineDiff {
  const TimelineDiff({
    required this.entityId,
    required this.kind,
    this.before,
    this.after,
  });

  final String entityId;
  final TimelineDiffKind kind;
  final Map<String, Object>? before;
  final Map<String, Object>? after;
}
