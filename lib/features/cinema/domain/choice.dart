/// Sprint 48 — Step 48.50–48.60 Choice Nodes, Branching, Gameplay Handoff, QTE.
class ChoiceNode {
  const ChoiceNode({
    required this.id,
    required this.prompt,
    this.choices = const [],
  });

  final String id;
  final String prompt;
  final List<ChoiceOption> choices;
}

class ChoiceOption {
  const ChoiceOption({
    required this.id,
    required this.label,
    required this.consequenceId,
    this.condition,
  });

  final String id;
  final String label;
  final String consequenceId;
  final String? condition;
}

class QuickTimeEvent {
  const QuickTimeEvent({
    required this.id,
    required this.prompt,
    required this.windowMs,
    this.successKey,
  });

  final String id;
  final String prompt;
  final int windowMs;
  final String? successKey;
}

class PlayerTransformHandoff {
  const PlayerTransformHandoff({
    required this.id,
    required this.fromCinematicId,
    required this.toGameEntityId,
    required this.positionX,
    required this.positionY,
  });

  final String id;
  final String fromCinematicId;
  final String toGameEntityId;
  final double positionX;
  final double positionY;
}
