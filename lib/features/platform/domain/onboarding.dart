/// Sprint 50 — Step 50.45–50.50 Welcome Experience, First-Run, Demo, Tutorials.
class OnboardingStep {
  const OnboardingStep({
    required this.id,
    required this.name,
    required this.skippable,
    this.completed = false,
  });

  final String id;
  final String name;
  final bool skippable;
  final bool completed;

  OnboardingStep markCompleted() =>
      OnboardingStep(id: id, name: name, skippable: skippable, completed: true);
}

class DemoProject {
  const DemoProject({
    required this.id,
    required this.name,
    required this.sizeMb,
  });

  final String id;
  final String name;
  final int sizeMb;
}

class TutorialTip {
  const TutorialTip({
    required this.id,
    required this.elementKey,
    required this.message,
    this.dismissed = false,
  });

  final String id;
  final String elementKey;
  final String message;
  final bool dismissed;

  TutorialTip markDismissed() => TutorialTip(
    id: id,
    elementKey: elementKey,
    message: message,
    dismissed: true,
  );

  bool get showAgain => !dismissed;
}
