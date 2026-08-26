import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/subplot/domain/story_quest.dart';

void main() {
  group('quest_schema', () {
    test('records objective, giver, status, and immutable identity', () {
      final quest = StoryQuest(
        id: 'q-rescue',
        title: 'Selamatkan Penjaga Kutub',
        objective: 'Temukan penjaga sebelum badai tiba.',
        giverEntityId: 'char-orin',
        status: StoryQuestStatus.available,
      );

      expect(quest.id, 'q-rescue');
      expect(quest.objective, contains('penjaga'));
      expect(quest.giverEntityId, 'char-orin');
      expect(quest.status, StoryQuestStatus.available);
      expect(
        quest.copyWith(status: StoryQuestStatus.active).status,
        StoryQuestStatus.active,
      );
      expect(quest.status, StoryQuestStatus.available);
    });

    test('rejects blank required fields', () {
      expect(
        () => StoryQuest(
          id: ' ',
          title: 'Quest',
          objective: 'Tujuan',
          giverEntityId: 'char-1',
          status: StoryQuestStatus.draft,
        ),
        throwsArgumentError,
      );
    });
  });

  group('dependency_schema', () {
    test('stores typed prerequisites and evaluates unlock state', () {
      final quest = StoryQuest(
        id: 'q-final',
        title: 'Gerbang Akhir',
        objective: 'Buka gerbang.',
        giverEntityId: 'char-1',
        status: StoryQuestStatus.locked,
        dependencies: [
          const StoryQuestDependency(
            questId: 'q-key',
            requiredStatus: StoryQuestStatus.completed,
          ),
          const StoryQuestDependency(
            questId: 'q-map',
            requiredStatus: StoryQuestStatus.completed,
          ),
        ],
      );

      expect(
        quest.dependenciesSatisfiedBy({
          'q-key': StoryQuestStatus.completed,
          'q-map': StoryQuestStatus.active,
        }),
        isFalse,
      );
      expect(
        quest.dependenciesSatisfiedBy({
          'q-key': StoryQuestStatus.completed,
          'q-map': StoryQuestStatus.completed,
        }),
        isTrue,
      );
    });

    test('graph rejects self-dependency, unknown target, and cycles', () {
      final a = StoryQuest(
        id: 'a',
        title: 'A',
        objective: 'A',
        giverEntityId: 'giver',
        status: StoryQuestStatus.locked,
        dependencies: [const StoryQuestDependency(questId: 'b')],
      );
      final b = StoryQuest(
        id: 'b',
        title: 'B',
        objective: 'B',
        giverEntityId: 'giver',
        status: StoryQuestStatus.locked,
        dependencies: [const StoryQuestDependency(questId: 'a')],
      );
      final self = StoryQuest(
        id: 'self',
        title: 'Self',
        objective: 'Self',
        giverEntityId: 'giver',
        status: StoryQuestStatus.locked,
        dependencies: [const StoryQuestDependency(questId: 'self')],
      );
      final unknown = StoryQuest(
        id: 'unknown',
        title: 'Unknown',
        objective: 'Unknown',
        giverEntityId: 'giver',
        status: StoryQuestStatus.locked,
        dependencies: [const StoryQuestDependency(questId: 'missing')],
      );

      expect(
        StoryQuestGraph([a, b]).validate(),
        contains('dependency_cycle:a'),
      );
      expect(
        StoryQuestGraph([self]).validate(),
        contains('self_dependency:self'),
      );
      expect(
        StoryQuestGraph([unknown]).validate(),
        contains('unknown_dependency:unknown:missing'),
      );
    });
  });

  group('stakeholder_links', () {
    test('links characters, locations, factions, and items with roles', () {
      final quest = StoryQuest(
        id: 'q-1',
        title: 'Perebutan Relik',
        objective: 'Amankan relik.',
        giverEntityId: 'char-giver',
        status: StoryQuestStatus.active,
        stakeholders: [
          const StoryQuestStakeholder(
            entityId: 'char-mira',
            entityType: StoryQuestEntityType.character,
            role: StoryQuestStakeholderRole.ally,
          ),
          const StoryQuestStakeholder(
            entityId: 'loc-volcano',
            entityType: StoryQuestEntityType.location,
            role: StoryQuestStakeholderRole.destination,
          ),
          const StoryQuestStakeholder(
            entityId: 'faction-ash',
            entityType: StoryQuestEntityType.faction,
            role: StoryQuestStakeholderRole.opponent,
          ),
          const StoryQuestStakeholder(
            entityId: 'item-cube',
            entityType: StoryQuestEntityType.item,
            role: StoryQuestStakeholderRole.subject,
          ),
        ],
      );

      expect(quest.stakeholders, hasLength(4));
      expect(
        quest.stakeholdersFor(StoryQuestEntityType.location).single.entityId,
        'loc-volcano',
      );
      expect(
        quest.stakeholders.map((link) => link.entityId).toSet(),
        hasLength(4),
      );
    });
  });

  group('outcome_schema', () {
    test('records distinct success and failure consequences', () {
      final quest = StoryQuest(
        id: 'q-1',
        title: 'Tahan Badai',
        objective: 'Lindungi desa.',
        giverEntityId: 'char-giver',
        status: StoryQuestStatus.active,
        outcomes: [
          const StoryQuestOutcome(
            kind: StoryQuestOutcomeKind.success,
            consequence: 'Desa bertahan.',
            affectedEntityIds: ['loc-village'],
          ),
          const StoryQuestOutcome(
            kind: StoryQuestOutcomeKind.failure,
            consequence: 'Pelabuhan membeku dan jalur suplai putus.',
            affectedEntityIds: ['loc-port', 'faction-traders'],
          ),
        ],
      );

      expect(
        quest.outcomeFor(StoryQuestOutcomeKind.success)?.consequence,
        'Desa bertahan.',
      );
      expect(
        quest.outcomeFor(StoryQuestOutcomeKind.failure)?.affectedEntityIds,
        ['loc-port', 'faction-traders'],
      );
    });

    test('terminal status requires its matching outcome', () {
      expect(
        () => StoryQuest(
          id: 'q-1',
          title: 'Quest',
          objective: 'Tujuan',
          giverEntityId: 'giver',
          status: StoryQuestStatus.failed,
          outcomes: const [
            StoryQuestOutcome(
              kind: StoryQuestOutcomeKind.success,
              consequence: 'Sukses.',
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
