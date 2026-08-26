/// Unresolved Subplot & Consequence Alerts (Step 109.43).
library;

import 'story_quest.dart';

enum SubplotAlertTrigger { unresolved, storyPoint, deadline }

enum SubplotClosureKind { resolved, dismissed }

class SubplotCheckpoint {
  const SubplotCheckpoint({
    required this.questId,
    required this.storyPoint,
    this.dueStoryPoint,
    this.dueAt,
  });
  final String questId;
  final int storyPoint;
  final int? dueStoryPoint;
  final DateTime? dueAt;
}

class SubplotAlert {
  const SubplotAlert({
    required this.id,
    required this.questId,
    required this.trigger,
    this.failureConsequence,
  });
  factory SubplotAlert.overdueStoryPoint({
    required String questId,
    required int dueStoryPoint,
    required int currentStoryPoint,
    String? failureConsequence,
  }) => SubplotAlert(
    id: '$questId:story_point:$dueStoryPoint',
    questId: questId,
    trigger: SubplotAlertTrigger.storyPoint,
    failureConsequence: failureConsequence,
  );
  final String id;
  final String questId;
  final SubplotAlertTrigger trigger;
  final String? failureConsequence;
}

class SubplotClosure {
  const SubplotClosure({
    required this.alertId,
    required this.kind,
    required this.reason,
    required this.at,
  });
  final String alertId;
  final SubplotClosureKind kind;
  final String reason;
  final DateTime at;
}

class SubplotAlertReport {
  SubplotAlertReport({
    Iterable<SubplotAlert> active = const [],
    Iterable<SubplotClosure> history = const [],
  }) : active = List.unmodifiable(active),
       history = List.unmodifiable(history);
  final List<SubplotAlert> active;
  final List<SubplotClosure> history;
  bool get isClean => active.isEmpty;

  SubplotAlertReport dismiss(
    String id, {
    required String reason,
    DateTime? at,
  }) => _close(id, SubplotClosureKind.dismissed, reason, at);
  SubplotAlertReport resolve(String id, {required String note, DateTime? at}) =>
      _close(id, SubplotClosureKind.resolved, note, at);

  SubplotAlertReport _close(
    String id,
    SubplotClosureKind kind,
    String reason,
    DateTime? at,
  ) {
    if (reason.trim().isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'must not be blank');
    }
    if (!active.any((alert) => alert.id == id)) {
      throw StateError('unknown active alert: $id');
    }
    return SubplotAlertReport(
      active: active.where((alert) => alert.id != id),
      history: [
        ...history,
        SubplotClosure(
          alertId: id,
          kind: kind,
          reason: reason,
          at: at ?? DateTime.now().toUtc(),
        ),
      ],
    );
  }
}

class SubplotAlertScanner {
  const SubplotAlertScanner();

  SubplotAlertReport scan({
    required Iterable<SubplotCheckpoint> quests,
    required Map<String, StoryQuestStatus> questCatalog,
    required int currentStoryPoint,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now().toUtc();
    final alerts = <SubplotAlert>[];
    for (final checkpoint in quests) {
      final status = questCatalog[checkpoint.questId];
      if (status == null ||
          {
            StoryQuestStatus.completed,
            StoryQuestStatus.failed,
            StoryQuestStatus.abandoned,
          }.contains(status)) {
        continue;
      }
      final pointDue = checkpoint.dueStoryPoint;
      if (pointDue != null && currentStoryPoint > pointDue) {
        alerts.add(
          SubplotAlert.overdueStoryPoint(
            questId: checkpoint.questId,
            dueStoryPoint: pointDue,
            currentStoryPoint: currentStoryPoint,
          ),
        );
      } else if (checkpoint.dueAt != null && clock.isAfter(checkpoint.dueAt!)) {
        alerts.add(
          SubplotAlert(
            id: '${checkpoint.questId}:deadline:${checkpoint.dueAt!.toIso8601String()}',
            questId: checkpoint.questId,
            trigger: SubplotAlertTrigger.deadline,
          ),
        );
      } else {
        alerts.add(
          SubplotAlert(
            id: '${checkpoint.questId}:unresolved',
            questId: checkpoint.questId,
            trigger: SubplotAlertTrigger.unresolved,
          ),
        );
      }
    }
    alerts.sort((a, b) => a.questId.compareTo(b.questId));
    return SubplotAlertReport(active: alerts);
  }

  SubplotAlertReport scanQuests({
    required Iterable<StoryQuest> quests,
    required Iterable<SubplotCheckpoint> checkpoints,
    required int currentStoryPoint,
    DateTime? now,
  }) {
    final byId = {for (final quest in quests) quest.id: quest};
    final base = scan(
      quests: checkpoints,
      questCatalog: {for (final quest in quests) quest.id: quest.status},
      currentStoryPoint: currentStoryPoint,
      now: now,
    );
    return SubplotAlertReport(
      active: base.active.map((alert) {
        final consequence = byId[alert.questId]
            ?.outcomeFor(StoryQuestOutcomeKind.failure)
            ?.consequence;
        return SubplotAlert(
          id: alert.id,
          questId: alert.questId,
          trigger: alert.trigger,
          failureConsequence: consequence,
        );
      }),
    );
  }
}
