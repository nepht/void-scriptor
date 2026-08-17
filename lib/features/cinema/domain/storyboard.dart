/// Sprint 48 — Step 48.46–48.49 Storyboard, Animatic.
class Storyboard {
  const Storyboard({
    required this.id,
    required this.cinematicId,
    this.panels = const [],
  });

  final String id;
  final String cinematicId;
  final List<StoryboardPanel> panels;
}

class StoryboardPanel {
  const StoryboardPanel({
    required this.id,
    required this.description,
    required this.frame,
    this.imageAssetId,
  });

  final String id;
  final String description;
  final int frame;
  final String? imageAssetId;
}

class Animatic {
  const Animatic({
    required this.id,
    required this.storyboardId,
    required this.durationSeconds,
  });

  final String id;
  final String storyboardId;
  final double durationSeconds;
}
