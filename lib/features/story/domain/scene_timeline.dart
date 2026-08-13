class TimelineBeatData {
  const TimelineBeatData({this.startSecond, this.durationSeconds});
  final double? startSecond;
  final double? durationSeconds;
}

class SceneTimelineValidation {
  const SceneTimelineValidation({
    required this.sceneDurationSeconds,
    required this.totalBeatDuration,
  });
  final double? sceneDurationSeconds;
  final double totalBeatDuration;
  bool get isMismatch =>
      sceneDurationSeconds != null &&
      (sceneDurationSeconds! - totalBeatDuration).abs() > 0.01;
}

class SceneTimelineValidator {
  static SceneTimelineValidation validate({
    required double? sceneDurationSeconds,
    required List<TimelineBeatData> beats,
  }) {
    final total = beats.fold<double>(
      0,
      (sum, beat) => sum + (beat.durationSeconds ?? 0),
    );
    return SceneTimelineValidation(
      sceneDurationSeconds: sceneDurationSeconds,
      totalBeatDuration: total,
    );
  }
}
