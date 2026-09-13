# Adversarial Bug Hunt Report: Timeline & Relations Vertical

## Summary
- Scope: 12 Dart files in relations and timeline features.
- Total Findings: 5
- Total Score: 31

---

**BUG-001** | Severity: Critical | Points: 10
- **File:** `lib/features/timeline/application/move_timeline_clip_command.dart`
- **Line(s):** 17-31
- **Category:** data-integrity
- **Claim:** `MoveTimelineClipCommand.fromRecord` crashes with a type cast error when reconstructing from an undo payload because `undoPayload` uses key `'startSeconds'` instead of `'oldStartSeconds'` and `'newStartSeconds'`.
- **Evidence:** 
```dart
  factory MoveTimelineClipCommand.fromRecord(
    CommandHistoryRecord record,
    CreateTimelineService timelineService,
  ) {
    return MoveTimelineClipCommand(
      id: record.id,
      projectId: record.projectId,
      timelineService: timelineService,
      clipId: record.payload['clipId']! as String,
      oldStartSeconds: (record.payload['oldStartSeconds']! as num).toDouble(),
      newStartSeconds: (record.payload['newStartSeconds']! as num).toDouble(),
      durationSeconds: (record.payload['durationSeconds']! as num).toDouble(),
    );
  }
...
  @override
  Map<String, Object?> get undoPayload => {
    'clipId': clipId,
    'startSeconds': oldStartSeconds,
    'durationSeconds': durationSeconds,
  };
```

---

**BUG-002** | Severity: Critical | Points: 10
- **File:** `lib/features/timeline/domain/timeline_model.dart`
- **Line(s):** 131-139
- **Category:** edge-case
- **Claim:** `validateTimeline` does not check for overlapping clips on the same track, allowing simultaneous colliding clip placements.
- **Evidence:**
```dart
TimelineValidation validateTimeline({
  required double durationSeconds,
  required List<TimelineClipModel> clips,
}) {
  final errors = <String>[];
  for (final clip in clips) {
    if (clip.startSeconds < 0) {
      errors.add('Clip ${clip.label} starts before 0 seconds');
    }
    if (clip.durationSeconds <= 0) {
      errors.add('Clip ${clip.label} has non-positive duration');
    }
    if (clip.endSeconds > durationSeconds) {
      errors.add('Clip ${clip.label} exceeds scene duration');
    }
  }
  return TimelineValidation(errors);
}
```

---

**BUG-003** | Severity: Medium | Points: 5
- **File:** `lib/features/relations/application/relation_command.dart`
- **Line(s):** 18-32
- **Category:** logic
- **Claim:** `RelationCommand.create` generates a new random UUID for the inner `AssetRelation` via `const Uuid().v4()` instead of using the command `id` parameter, causing command tracking/correlation mismatch.
- **Evidence:**
```dart
  RelationCommand.create({
    required String id,
    required String projectId,
    required RelationRepository repository,
    required String sourceAssetId,
    required String targetAssetId,
    required AssetRelationType type,
    DateTime? createdAt,
  }) : this._(
         id: id,
         projectId: projectId,
         repository: repository,
         relation: AssetRelation(
           id: const Uuid().v4(),
           projectId: projectId,
           sourceAssetId: sourceAssetId,
           targetAssetId: targetAssetId,
           type: type,
           createdAt: createdAt ?? DateTime.now().toUtc(),
         ),
         createRelation: true,
       );
```

---

**BUG-004** | Severity: Medium | Points: 5
- **File:** `lib/features/timeline/presentation/timeline_workspace_screen.dart`
- **Line(s):** 36-39
- **Category:** error-handling
- **Claim:** `_moveClip` can pass a negative upper bound to `.clamp(0.0, maxStart)` if a clip's duration exceeds scene duration, throwing an `ArgumentError`.
- **Evidence:**
```dart
  void _moveClip(TimelineClipModel clip, double deltaSeconds) {
    final maxStart = widget.durationSeconds - clip.durationSeconds;
    final start = snapSeconds(
      (clip.startSeconds + deltaSeconds).clamp(0.0, maxStart),
      TimelineSnapMode.tenthSecond,
      30,
    );
```

---

**BUG-005** | Severity: Low | Points: 1
- **File:** `lib/features/timeline/application/create_timeline_service.dart`
- **Line(s):** 60-67
- **Category:** error-handling
- **Claim:** `ensureTimelineForScene` calls `getSingle()` on the action track query without fallback or null check, risking an unhandled `StateError` if the action track was omitted or corrupted.
- **Evidence:**
```dart
      final actionTrack =
          await (database.select(database.timelineTracks)..where(
                (row) =>
                    row.timelineId.equals(timelineId) &
                    row.trackType.equals(TimelineTrackType.action.name),
              ))
              .getSingle();
```

---

TOTAL FINDINGS: 5
TOTAL SCORE: 31
