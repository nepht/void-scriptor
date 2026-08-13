import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/domain/scene_timeline.dart';

void main() {
  test('duration validation reports beat total mismatch', () {
    final result = SceneTimelineValidator.validate(
      sceneDurationSeconds: 10,
      beats: const [
        TimelineBeatData(startSecond: 0, durationSeconds: 2),
        TimelineBeatData(startSecond: 2, durationSeconds: 3),
        TimelineBeatData(startSecond: 5, durationSeconds: 7),
      ],
    );
    expect(result.isMismatch, isTrue);
    expect(result.totalBeatDuration, 12);
  });

  test('duration validation accepts an exact scene timeline', () {
    final result = SceneTimelineValidator.validate(
      sceneDurationSeconds: 10,
      beats: const [
        TimelineBeatData(startSecond: 0, durationSeconds: 2),
        TimelineBeatData(startSecond: 2, durationSeconds: 8),
      ],
    );
    expect(result.isMismatch, isFalse);
  });
}
