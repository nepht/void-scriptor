import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/subplot/domain/mission_board.dart';
import 'package:void_scriptor/features/subplot/domain/story_quest.dart';

void main() {
  StoryQuest quest({
    required String id,
    required StoryQuestStatus status,
    List<StoryQuestDependency> dependencies = const [],
    List<StoryQuestStakeholder> stakeholders = const [],
    List<StoryQuestOutcome> outcomes = const [],
  }) => StoryQuest(
    id: id,
    title: 'Quest $id',
    objective: 'Objective $id',
    giverEntityId: 'giver-$id',
    status: status,
    dependencies: dependencies,
    stakeholders: stakeholders,
    outcomes: outcomes,
  );

  final quests = [
    quest(id: 'draft', status: StoryQuestStatus.draft),
    quest(
      id: 'locked',
      status: StoryQuestStatus.locked,
      dependencies: const [StoryQuestDependency(questId: 'done')],
    ),
    quest(id: 'open', status: StoryQuestStatus.available),
    quest(
      id: 'active',
      status: StoryQuestStatus.active,
      stakeholders: const [
        StoryQuestStakeholder(
          entityId: 'char-mira',
          entityType: StoryQuestEntityType.character,
          role: StoryQuestStakeholderRole.ally,
        ),
      ],
    ),
    quest(
      id: 'done',
      status: StoryQuestStatus.completed,
      outcomes: const [
        StoryQuestOutcome(
          kind: StoryQuestOutcomeKind.success,
          consequence: 'Selesai.',
        ),
      ],
    ),
  ];

  final links = [
    const MissionStoryLink(
      questId: 'active',
      targetId: 'scene-7',
      targetType: MissionStoryLinkType.scene,
      role: MissionStoryLinkRole.appearsIn,
    ),
    const MissionStoryLink(
      questId: 'active',
      targetId: 'arc-main',
      targetType: MissionStoryLinkType.arc,
      role: MissionStoryLinkRole.belongsTo,
    ),
    const MissionStoryLink(
      questId: 'open',
      targetId: 'loc-pole',
      targetType: MissionStoryLinkType.location,
      role: MissionStoryLinkRole.destination,
    ),
    const MissionStoryLink(
      questId: 'open',
      targetId: 'char-orin',
      targetType: MissionStoryLinkType.character,
      role: MissionStoryLinkRole.involves,
    ),
  ];

  group('board_views', () {
    test('list view is stable and status view groups every quest', () {
      final board = MissionBoard(quests: quests, links: links);

      expect(board.listView.map((card) => card.quest.id), [
        'active',
        'done',
        'draft',
        'locked',
        'open',
      ]);
      expect(
        board.statusView[StoryQuestStatus.active]?.single.quest.id,
        'active',
      );
      expect(
        board.statusView.values
            .expand((cards) => cards)
            .map((card) => card.quest.id)
            .toSet(),
        quests.map((quest) => quest.id).toSet(),
      );
    });
  });

  group('story_links', () {
    test('resolves scene, character, location and arc links per card', () {
      final board = MissionBoard(quests: quests, links: links);

      expect(
        board.cardFor('active').links.map((link) => link.targetType).toSet(),
        {MissionStoryLinkType.scene, MissionStoryLinkType.arc},
      );
      expect(
        board.cardFor('open').links.map((link) => link.targetType).toSet(),
        {MissionStoryLinkType.location, MissionStoryLinkType.character},
      );
    });

    test('rejects links to unknown quests', () {
      expect(
        () => MissionBoard(
          quests: quests,
          links: const [
            MissionStoryLink(
              questId: 'missing',
              targetId: 'scene-1',
              targetType: MissionStoryLinkType.scene,
              role: MissionStoryLinkRole.appearsIn,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('status_flow', () {
    test('allows canonical transitions and rejects invalid jumps', () {
      const flow = MissionStatusFlow();

      expect(
        flow.canTransition(StoryQuestStatus.draft, StoryQuestStatus.available),
        isTrue,
      );
      expect(
        flow.canTransition(StoryQuestStatus.available, StoryQuestStatus.active),
        isTrue,
      );
      expect(
        flow.canTransition(StoryQuestStatus.active, StoryQuestStatus.completed),
        isTrue,
      );
      expect(
        flow.canTransition(StoryQuestStatus.active, StoryQuestStatus.failed),
        isTrue,
      );
      expect(
        flow.canTransition(StoryQuestStatus.completed, StoryQuestStatus.active),
        isFalse,
      );
      expect(
        () => flow.transition(
          quests.firstWhere((quest) => quest.id == 'done'),
          StoryQuestStatus.active,
        ),
        throwsStateError,
      );
    });
  });

  group('dependency_view', () {
    test('shows prerequisite status and whether a locked quest can unlock', () {
      final board = MissionBoard(quests: quests, links: links);
      final dependency = board.cardFor('locked').dependencies.single;

      expect(dependency.questId, 'done');
      expect(dependency.currentStatus, StoryQuestStatus.completed);
      expect(dependency.requiredStatus, StoryQuestStatus.completed);
      expect(dependency.isSatisfied, isTrue);
      expect(board.cardFor('locked').dependenciesSatisfied, isTrue);
    });
  });

  group('filters', () {
    test('combines status, entity type and text deterministically', () {
      final board = MissionBoard(quests: quests, links: links);

      expect(
        board
            .filter(
              const MissionBoardFilter(
                statuses: {StoryQuestStatus.active},
                linkedEntityTypes: {MissionStoryLinkType.scene},
                query: 'ACTIVE',
              ),
            )
            .map((card) => card.quest.id),
        ['active'],
      );
      expect(
        board
            .filter(
              const MissionBoardFilter(
                linkedEntityTypes: {MissionStoryLinkType.location},
              ),
            )
            .map((card) => card.quest.id),
        ['open'],
      );
    });

    test('empty filter returns the stable list view', () {
      final board = MissionBoard(quests: quests, links: links);
      expect(board.filter(const MissionBoardFilter()), board.listView);
    });
  });
}
