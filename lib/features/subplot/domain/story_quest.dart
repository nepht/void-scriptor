/// Subplot & Quest Data Model (Step 109.41).
library;

enum StoryQuestStatus {
  draft,
  locked,
  available,
  active,
  completed,
  failed,
  abandoned,
}

enum StoryQuestEntityType { character, location, faction, item }

enum StoryQuestStakeholderRole {
  giver,
  ally,
  opponent,
  destination,
  subject,
  beneficiary,
}

enum StoryQuestOutcomeKind { success, failure }

class StoryQuestDependency {
  const StoryQuestDependency({
    required this.questId,
    this.requiredStatus = StoryQuestStatus.completed,
  });

  final String questId;
  final StoryQuestStatus requiredStatus;
}

class StoryQuestStakeholder {
  const StoryQuestStakeholder({
    required this.entityId,
    required this.entityType,
    required this.role,
  });

  final String entityId;
  final StoryQuestEntityType entityType;
  final StoryQuestStakeholderRole role;
}

class StoryQuestOutcome {
  const StoryQuestOutcome({
    required this.kind,
    required this.consequence,
    this.affectedEntityIds = const <String>[],
  });

  final StoryQuestOutcomeKind kind;
  final String consequence;
  final List<String> affectedEntityIds;
}

class StoryQuest {
  StoryQuest({
    required String id,
    required String title,
    required String objective,
    required String giverEntityId,
    required this.status,
    List<StoryQuestDependency> dependencies = const <StoryQuestDependency>[],
    List<StoryQuestStakeholder> stakeholders = const <StoryQuestStakeholder>[],
    List<StoryQuestOutcome> outcomes = const <StoryQuestOutcome>[],
  }) : id = _required(id, 'id'),
       title = _required(title, 'title'),
       objective = _required(objective, 'objective'),
       giverEntityId = _required(giverEntityId, 'giverEntityId'),
       dependencies = List<StoryQuestDependency>.unmodifiable(dependencies),
       stakeholders = List<StoryQuestStakeholder>.unmodifiable(stakeholders),
       outcomes = List<StoryQuestOutcome>.unmodifiable(outcomes) {
    _validateTerminalOutcome(status, this.outcomes);
  }

  final String id;
  final String title;
  final String objective;
  final String giverEntityId;
  final StoryQuestStatus status;
  final List<StoryQuestDependency> dependencies;
  final List<StoryQuestStakeholder> stakeholders;
  final List<StoryQuestOutcome> outcomes;

  StoryQuest copyWith({
    String? title,
    String? objective,
    String? giverEntityId,
    StoryQuestStatus? status,
    List<StoryQuestDependency>? dependencies,
    List<StoryQuestStakeholder>? stakeholders,
    List<StoryQuestOutcome>? outcomes,
  }) => StoryQuest(
    id: id,
    title: title ?? this.title,
    objective: objective ?? this.objective,
    giverEntityId: giverEntityId ?? this.giverEntityId,
    status: status ?? this.status,
    dependencies: dependencies ?? this.dependencies,
    stakeholders: stakeholders ?? this.stakeholders,
    outcomes: outcomes ?? this.outcomes,
  );

  bool dependenciesSatisfiedBy(Map<String, StoryQuestStatus> statuses) =>
      dependencies.every(
        (dependency) =>
            statuses[dependency.questId] == dependency.requiredStatus,
      );

  List<StoryQuestStakeholder> stakeholdersFor(StoryQuestEntityType type) =>
      List<StoryQuestStakeholder>.unmodifiable(
        stakeholders.where((stakeholder) => stakeholder.entityType == type),
      );

  StoryQuestOutcome? outcomeFor(StoryQuestOutcomeKind kind) {
    for (final outcome in outcomes) {
      if (outcome.kind == kind) return outcome;
    }
    return null;
  }

  static String _required(String value, String field) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, field, 'must not be blank');
    }
    return value;
  }

  static void _validateTerminalOutcome(
    StoryQuestStatus status,
    List<StoryQuestOutcome> outcomes,
  ) {
    final required = switch (status) {
      StoryQuestStatus.completed => StoryQuestOutcomeKind.success,
      StoryQuestStatus.failed => StoryQuestOutcomeKind.failure,
      _ => null,
    };
    if (required != null &&
        !outcomes.any((outcome) => outcome.kind == required)) {
      throw ArgumentError(
        'terminal status ${status.name} requires ${required.name} outcome',
      );
    }
  }
}

class StoryQuestGraph {
  StoryQuestGraph(Iterable<StoryQuest> quests)
    : quests = Map<String, StoryQuest>.unmodifiable({
        for (final quest in quests) quest.id: quest,
      });

  final Map<String, StoryQuest> quests;

  List<String> validate() {
    final issues = <String>[];
    for (final quest in quests.values) {
      for (final dependency in quest.dependencies) {
        if (dependency.questId == quest.id) {
          issues.add('self_dependency:${quest.id}');
        } else if (!quests.containsKey(dependency.questId)) {
          issues.add('unknown_dependency:${quest.id}:${dependency.questId}');
        }
      }
    }

    final visiting = <String>{};
    final visited = <String>{};
    bool visit(String id) {
      if (visiting.contains(id)) return true;
      if (visited.contains(id)) return false;
      visiting.add(id);
      final quest = quests[id];
      if (quest != null) {
        for (final dependency in quest.dependencies) {
          if (quests.containsKey(dependency.questId) &&
              visit(dependency.questId)) {
            return true;
          }
        }
      }
      visiting.remove(id);
      visited.add(id);
      return false;
    }

    for (final id in quests.keys) {
      visiting.clear();
      if (visit(id)) {
        issues.add('dependency_cycle:$id');
        break;
      }
    }
    return List<String>.unmodifiable(issues);
  }
}
