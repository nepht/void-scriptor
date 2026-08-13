class TimelineModel {
  const TimelineModel({
    required this.id,
    required this.projectId,
    required this.sceneId,
    required this.durationSeconds,
    this.frameRate = 30,
  });
  final String id;
  final String projectId;
  final String sceneId;
  final double durationSeconds;
  final int frameRate;
}

enum TimelineTrackType {
  character,
  camera,
  action,
  dialogue,
  vfx,
  audio,
  environment,
  continuity,
}

enum TimelineSnapMode {
  none,
  frame,
  tenthSecond,
  quarterSecond,
  halfSecond,
  second,
}

class TimelineClipModel {
  const TimelineClipModel({
    required this.id,
    required this.trackId,
    required this.startSeconds,
    required this.durationSeconds,
    required this.label,
    this.sourceId,
    this.clipType = 'generic',
    this.payload = '{}',
    this.sortOrder = 0,
  });
  final String id;
  final String trackId;
  final double startSeconds;
  final double durationSeconds;
  final String label;
  final String? sourceId;
  final String clipType;
  final String payload;
  final int sortOrder;
  double get endSeconds => startSeconds + durationSeconds;
}

class TimelineValidation {
  const TimelineValidation(this.errors);
  final List<String> errors;
  bool get isValid => errors.isEmpty;
}

class TimelineScale {
  const TimelineScale({required this.pixelsPerSecond});
  final double pixelsPerSecond;
  double secondsToPixels(double seconds) => seconds * pixelsPerSecond;
  double pixelsToSeconds(double pixels) => pixels / pixelsPerSecond;
}

double frameToSeconds(int frame, int fps) => frame / fps;
int secondsToFrame(double seconds, int fps) => (seconds * fps).round();

double snapSeconds(double seconds, TimelineSnapMode mode, int fps) {
  final step = switch (mode) {
    TimelineSnapMode.none => 0.0,
    TimelineSnapMode.frame => 1 / fps,
    TimelineSnapMode.tenthSecond => 0.1,
    TimelineSnapMode.quarterSecond => 0.25,
    TimelineSnapMode.halfSecond => 0.5,
    TimelineSnapMode.second => 1.0,
  };
  if (step == 0) return seconds;
  return (seconds / step).round() * step;
}

TimelineValidation validateTimeline({
  required double durationSeconds,
  required List<TimelineClipModel> clips,
}) {
  final errors = <String>[];
  for (final clip in clips) {
    if (clip.startSeconds < 0) {
      errors.add('Clip ${clip.label} starts before 0 seconds');
    }
    if (clip.durationSeconds <= 0) {
      errors.add('Clip ${clip.label} has non-positive duration');
    }
    if (clip.endSeconds > durationSeconds) {
      errors.add('Clip ${clip.label} exceeds scene duration');
    }
  }
  return TimelineValidation(errors);
}
