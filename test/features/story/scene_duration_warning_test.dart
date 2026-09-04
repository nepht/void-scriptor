import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/domain/scene_timeline.dart';
import 'package:void_scriptor/features/story/presentation/scene_duration_warning.dart';

void main() {
  test('missing scene duration does not report a mismatch', () {
    final result = SceneTimelineValidator.validate(
      sceneDurationSeconds: null,
      beats: const [TimelineBeatData(durationSeconds: 4)],
    );

    expect(result.totalBeatDuration, 4);
    expect(result.isMismatch, isFalse);
  });

  test('difference at the tolerance boundary is accepted', () {
    final result = SceneTimelineValidator.validate(
      sceneDurationSeconds: 10,
      beats: const [TimelineBeatData(durationSeconds: 10.01)],
    );

    expect(result.isMismatch, isFalse);
  });

  test('beat without duration contributes zero seconds', () {
    final result = SceneTimelineValidator.validate(
      sceneDurationSeconds: 5,
      beats: const [
        TimelineBeatData(durationSeconds: null),
        TimelineBeatData(durationSeconds: 5),
      ],
    );

    expect(result.totalBeatDuration, 5);
    expect(result.isMismatch, isFalse);
  });

  testWidgets('duration warning renders only for a mismatch', (tester) async {
    const mismatch = SceneTimelineValidation(
      sceneDurationSeconds: 10,
      totalBeatDuration: 12,
    );
    const exact = SceneTimelineValidation(
      sceneDurationSeconds: 10,
      totalBeatDuration: 10,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SceneDurationWarning(validation: mismatch)),
      ),
    );
    expect(find.text('Scene duration mismatch'), findsOneWidget);
    expect(find.text('Scene: 10.0 sec · Beats: 12.0 sec'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SceneDurationWarning(validation: exact)),
      ),
    );
    expect(find.text('Scene duration mismatch'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
