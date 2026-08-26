import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/subplot/domain/story_quest.dart';
import 'package:void_scriptor/features/subplot/domain/subplot_alerts.dart';

void main() {
  StoryQuest quest({
    required String id,
    required StoryQuestStatus status,
    List<StoryQuestOutcome> outcomes = const [],
  }) => StoryQuest(
    id: id,
    title: 'Quest $id',
    objective: 'Tujuan $id',
    giverEntityId: 'giver',
    status: status,
    outcomes: outcomes,
  );

  group('unresolved_report', () {
    test('reports active and available subplots but not terminal quests', () {
      final report = const SubplotAlertScanner().scan(
        quests: [
          const SubplotCheckpoint(questId: 'open', storyPoint: 4),
          const SubplotCheckpoint(questId: 'done', storyPoint: 3),
        ],
        questCatalog: {
          'open': StoryQuestStatus.active,
          'done': StoryQuestStatus.completed,
        },
        currentStoryPoint: 8,
      );
      expect(report.active.map((a) => a.questId), ['open']);
      expect(report.isClean, isFalse);
    });
  });

  group('deadline_or_story_point', () {
    test('flags passed story point and timestamp with explicit trigger', () {
      final report = const SubplotAlertScanner().scan(
        quests: [
          const SubplotCheckpoint(
            questId: 'point',
            storyPoint: 2,
            dueStoryPoint: 5,
          ),
          SubplotCheckpoint(
            questId: 'time',
            storyPoint: 2,
            dueAt: DateTime.utc(2026, 8, 1),
          ),
        ],
        questCatalog: {
          'point': StoryQuestStatus.active,
          'time': StoryQuestStatus.available,
        },
        currentStoryPoint: 6,
        now: DateTime.utc(2026, 8, 2),
      );
      expect(report.active.map((a) => a.trigger).toSet(), {
        SubplotAlertTrigger.storyPoint,
        SubplotAlertTrigger.deadline,
      });
    });
  });

  group('failure_consequence', () {
    test('carries failure consequence into overdue alert', () {
      final q = quest(
        id: 'q',
        status: StoryQuestStatus.active,
        outcomes: const [
          StoryQuestOutcome(
            kind: StoryQuestOutcomeKind.failure,
            consequence: 'Pelabuhan membeku.',
          ),
        ],
      );
      final report = const SubplotAlertScanner().scanQuests(
        quests: [q],
        checkpoints: const [
          SubplotCheckpoint(questId: 'q', storyPoint: 1, dueStoryPoint: 2),
        ],
        currentStoryPoint: 3,
      );
      expect(report.active.single.failureConsequence, 'Pelabuhan membeku.');
    });
  });

  group('dismissal_reason', () {
    test('dismissal requires reason and removes alert from active list', () {
      final alert = SubplotAlert.overdueStoryPoint(
        questId: 'q',
        dueStoryPoint: 2,
        currentStoryPoint: 3,
      );
      final report = SubplotAlertReport(active: [alert]);
      expect(() => report.dismiss(alert.id, reason: ' '), throwsArgumentError);
      final dismissed = report.dismiss(alert.id, reason: 'Sengaja ditunda.');
      expect(dismissed.active, isEmpty);
      expect(dismissed.history.single.reason, 'Sengaja ditunda.');
    });
  });

  group('closure_history', () {
    test('resolved and dismissed closures are append-only and ordered', () {
      final a = SubplotAlert.overdueStoryPoint(
        questId: 'a',
        dueStoryPoint: 1,
        currentStoryPoint: 2,
      );
      final b = SubplotAlert.overdueStoryPoint(
        questId: 'b',
        dueStoryPoint: 1,
        currentStoryPoint: 2,
      );
      final initial = SubplotAlertReport(active: [a, b]);
      final closedA = initial.resolve(
        a.id,
        note: 'Diterapkan di bab 4.',
        at: DateTime.utc(2026, 8, 1),
      );
      final closedB = closedA.dismiss(
        b.id,
        reason: 'Arc dihapus.',
        at: DateTime.utc(2026, 8, 2),
      );
      expect(closedB.history.map((h) => h.kind), [
        SubplotClosureKind.resolved,
        SubplotClosureKind.dismissed,
      ]);
      expect(initial.history, isEmpty);
      expect(closedB.active, isEmpty);
    });
  });
}
