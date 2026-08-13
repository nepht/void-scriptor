import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/timeline/domain/timeline_model.dart';

void main() {
  test('timeline scale converts seconds and pixels', () {
    const scale = TimelineScale(pixelsPerSecond: 80);
    expect(scale.secondsToPixels(2.5), 200);
    expect(scale.pixelsToSeconds(200), 2.5);
  });

  test('frame helpers round-trip using fps', () {
    expect(secondsToFrame(frameToSeconds(45, 30), 30), 45);
  });

  test('snap modes snap timeline time', () {
    expect(snapSeconds(1.26, TimelineSnapMode.tenthSecond, 30), 1.3);
    expect(
      snapSeconds(1.26, TimelineSnapMode.frame, 30),
      closeTo(1.2666667, 0.00001),
    );
  });

  test('timeline validator reports invalid clips', () {
    final validation = validateTimeline(
      durationSeconds: 10,
      clips: [
        const TimelineClipModel(
          id: 'a',
          trackId: 'camera',
          startSeconds: -1,
          durationSeconds: 2,
          label: 'bad',
        ),
        const TimelineClipModel(
          id: 'b',
          trackId: 'camera',
          startSeconds: 9,
          durationSeconds: 2,
          label: 'late',
        ),
      ],
    );
    expect(validation.errors, contains('Clip bad starts before 0 seconds'));
    expect(validation.errors, contains('Clip late exceeds scene duration'));
  });
}
