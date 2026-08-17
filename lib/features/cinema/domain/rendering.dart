/// Sprint 48 — Step 48.67–48.71 Render Queue, Presets, Passes.
enum RenderStatus { queued, rendering, completed, failed, cancelled }

class RenderPreset {
  const RenderPreset({
    required this.id,
    required this.name,
    required this.frameRate,
    required this.aspectRatio,
    this.optionalPasses = const [],
  });

  final String id;
  final String name;
  final int frameRate;
  final String aspectRatio;
  final List<String> optionalPasses;
}

class RenderQueueJob {
  const RenderQueueJob({
    required this.id,
    required this.cinematicId,
    required this.presetId,
    required this.status,
  });

  final String id;
  final String cinematicId;
  final String presetId;
  final RenderStatus status;
}
