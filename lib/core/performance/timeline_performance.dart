class TimelineViewport {
  const TimelineViewport({
    required this.startSeconds,
    required this.endSeconds,
    required this.pixelsPerSecond,
    this.overscanSeconds = 1,
  });

  final double startSeconds;
  final double endSeconds;
  final double pixelsPerSecond;
  final double overscanSeconds;

  double get queryStart => startSeconds - overscanSeconds;
  double get queryEnd => endSeconds + overscanSeconds;

  List<String> visibleClipIds(Iterable<TimelineClipBounds> clips) => clips
      .where((clip) => clip.end >= queryStart && clip.start <= queryEnd)
      .map((clip) => clip.id)
      .toList(growable: false);
}

class TimelineClipBounds {
  const TimelineClipBounds({
    required this.id,
    required this.start,
    required this.end,
  });

  final String id;
  final double start;
  final double end;
}

enum WaveformResolution {
  coarse,
  medium,
  fine;

  static WaveformResolution forPixelsPerSecond(double pixelsPerSecond) {
    if (pixelsPerSecond < 10) return coarse;
    if (pixelsPerSecond < 50) return medium;
    return fine;
  }
}
