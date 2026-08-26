/// Mission Board & Story Links (Step 109.42).
library;

import 'story_quest.dart';

enum MissionStoryLinkType { scene, character, location, arc }

enum MissionStoryLinkRole { appearsIn, involves, destination, belongsTo }

class MissionStoryLink {
  const MissionStoryLink({
    required this.questId,
    required this.targetId,
    required this.targetType,
    required this.role,
  });

  final String questId;
  final String targetId;
  final MissionStoryLinkType targetType;
  final MissionStoryLinkRole role;
}

class MissionDependencyView {
  const MissionDependencyView({
    required this.questId,
    required this.requiredStatus,
    required this.currentStatus,
  });

  final String questId;
  final StoryQuestStatus requiredStatus;
  final StoryQuestStatus? currentStatus;

  bool get isSatisfied => currentStatus == requiredStatus;
}

class MissionBoardCard {
  const MissionBoardCard({
    required this.quest,
    required this.links,
    required this.dependencies,
  });

  final StoryQuest quest;
  final List<MissionStoryLink> links;
  final List<MissionDependencyView> dependencies;

  bool get dependenciesSatisfied =>
      dependencies.every((dependency) => dependency.isSatisfied);
}

class MissionBoardFilter {
  const MissionBoardFilter({
    this.statuses = const <StoryQuestStatus>{},
    this.linkedEntityTypes = const <MissionStoryLinkType>{},
    this.query = '',
  });

  final Set<StoryQuestStatus> statuses;
  final Set<MissionStoryLinkType> linkedEntityTypes;
  final String query;
}

class MissionStatusFlow {
  const MissionStatusFlow();

  static const Map<StoryQuestStatus, Set<StoryQuestStatus>> _transitions = {
    StoryQuestStatus.draft: {
      StoryQuestStatus.locked,
      StoryQuestStatus.available,
      StoryQuestStatus.abandoned,
    },
    StoryQuestStatus.locked: {
      StoryQuestStatus.available,
      StoryQuestStatus.abandoned,
    },
    StoryQuestStatus.available: {
      StoryQuestStatus.active,
      StoryQuestStatus.abandoned,
    },
    StoryQuestStatus.active: {
      StoryQuestStatus.completed,
      StoryQuestStatus.failed,
      StoryQuestStatus.abandoned,
    },
    StoryQuestStatus.completed: <StoryQuestStatus>{},
    StoryQuestStatus.failed: <StoryQuestStatus>{},
    StoryQuestStatus.abandoned: <StoryQuestStatus>{},
  };

  bool canTransition(StoryQuestStatus from, StoryQuestStatus to) =>
      _transitions[from]?.contains(to) ?? false;

  StoryQuest transition(StoryQuest quest, StoryQuestStatus target) {
    if (!canTransition(quest.status, target)) {
      throw StateError(
        'invalid quest transition: ${quest.status.name} -> ${target.name}',
      );
    }
    return quest.copyWith(status: target);
  }
}

class MissionBoard {
  MissionBoard({
    required Iterable<StoryQuest> quests,
    Iterable<MissionStoryLink> links = const <MissionStoryLink>[],
  }) : _quests = Map<String, StoryQuest>.unmodifiable({
         for (final quest in quests) quest.id: quest,
       }),
       _links = List<MissionStoryLink>.unmodifiable(links) {
    for (final link in _links) {
      if (!_quests.containsKey(link.questId)) {
        throw ArgumentError(
          'story link references unknown quest: ${link.questId}',
        );
      }
    }
    _cards = List<MissionBoardCard>.unmodifiable(
      _quests.values.map(_buildCard).toList()
        ..sort((a, b) => a.quest.id.compareTo(b.quest.id)),
    );
  }

  final Map<String, StoryQuest> _quests;
  final List<MissionStoryLink> _links;
  late final List<MissionBoardCard> _cards;

  List<MissionBoardCard> get listView => _cards;

  Map<StoryQuestStatus, List<MissionBoardCard>> get statusView =>
      Map<StoryQuestStatus, List<MissionBoardCard>>.unmodifiable({
        for (final status in StoryQuestStatus.values)
          status: List<MissionBoardCard>.unmodifiable(
            _cards.where((card) => card.quest.status == status),
          ),
      });

  MissionBoardCard cardFor(String questId) {
    for (final card in _cards) {
      if (card.quest.id == questId) return card;
    }
    throw StateError('unknown quest: $questId');
  }

  List<MissionBoardCard> filter(MissionBoardFilter filter) {
    final query = filter.query.trim().toLowerCase();
    if (filter.statuses.isEmpty &&
        filter.linkedEntityTypes.isEmpty &&
        query.isEmpty) {
      return listView;
    }
    return List<MissionBoardCard>.unmodifiable(
      _cards.where((card) {
        final statusMatches =
            filter.statuses.isEmpty ||
            filter.statuses.contains(card.quest.status);
        final typeMatches =
            filter.linkedEntityTypes.isEmpty ||
            card.links.any(
              (link) => filter.linkedEntityTypes.contains(link.targetType),
            );
        final queryMatches =
            query.isEmpty ||
            card.quest.id.toLowerCase().contains(query) ||
            card.quest.title.toLowerCase().contains(query) ||
            card.quest.objective.toLowerCase().contains(query);
        return statusMatches && typeMatches && queryMatches;
      }),
    );
  }

  MissionBoardCard _buildCard(StoryQuest quest) => MissionBoardCard(
    quest: quest,
    links: List<MissionStoryLink>.unmodifiable(
      _links.where((link) => link.questId == quest.id),
    ),
    dependencies: List<MissionDependencyView>.unmodifiable(
      quest.dependencies.map(
        (dependency) => MissionDependencyView(
          questId: dependency.questId,
          requiredStatus: dependency.requiredStatus,
          currentStatus: _quests[dependency.questId]?.status,
        ),
      ),
    ),
  );
}
