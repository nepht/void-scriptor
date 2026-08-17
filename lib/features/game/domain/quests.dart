/// Sprint 47 — Step 47.44–47.50 Quest & Dialogue Systems.
enum QuestType { main, side, dynamic, daily, event }

enum QuestStatus { notStarted, inProgress, completed, failed, abandoned }

class Quest {
  const Quest({
    required this.id,
    required this.title,
    required this.type,
    this.status = QuestStatus.notStarted,
  });

  final String id;
  final String title;
  final QuestType type;
  final QuestStatus status;

  Quest start() =>
      Quest(id: id, title: title, type: type, status: QuestStatus.inProgress);
}

class DialogueNode {
  const DialogueNode({
    required this.id,
    required this.speaker,
    required this.text,
    this.choices = const [],
  });

  final String id;
  final String speaker;
  final String text;
  final List<DialogueChoice> choices;
}

class DialogueChoice {
  const DialogueChoice({
    required this.id,
    required this.label,
    required this.nextNodeId,
  });

  final String id;
  final String label;
  final String nextNodeId;
}
