import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/export/domain/clean_export.dart';
import 'package:void_scriptor/features/export/domain/export_preflight.dart';
import 'package:void_scriptor/features/export/domain/export_profiles.dart';
import 'package:void_scriptor/features/subplot/domain/mission_board.dart';
import 'package:void_scriptor/features/subplot/domain/story_quest.dart';
import 'package:void_scriptor/features/subplot/domain/subplot_alerts.dart';

void main() {
  test('109 end-to-end narrative export path composes verified contracts', () {
    final quest = StoryQuest(
      id: 'q-e2e',
      title: 'Quest',
      objective: 'Objective',
      giverEntityId: 'char-1',
      status: StoryQuestStatus.active,
    );
    final board = MissionBoard(quests: [quest]);
    final alerts = const SubplotAlertScanner().scan(
      quests: const [SubplotCheckpoint(questId: 'q-e2e', storyPoint: 1)],
      questCatalog: const {'q-e2e': StoryQuestStatus.active},
      currentStoryPoint: 1,
    );
    final cleaned = const CleanExportTransformer().transform(
      '# Scene\n[[PRIVATE:todo]]\nSee [[Quest]]',
    );
    final preflight = const ExportPreflightValidator().validate(
      ExportPreflightRequest(
        documentId: 'story-e2e',
        sourceText: cleaned.text,
        profile: ExportProfile.plainText(),
      ),
    );

    expect(board.cardFor('q-e2e').quest.id, 'q-e2e');
    expect(alerts.active.single.questId, 'q-e2e');
    expect(cleaned.text, '# Scene\n\nSee Quest');
    expect(preflight.isReady, isTrue);
    expect(preflight.manifest.documentId, 'story-e2e');
  });
}
