import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/timeline/domain/timeline_model.dart';
import 'package:void_scriptor/features/timeline/presentation/timeline_workspace_screen.dart';

// Regression for vs-hunt-20260913-timeline-relations BUG-004 (Referee: REAL, Medium).
//
// _moveClip computes `maxStart = durationSeconds - clip.durationSeconds` and calls
// `(...).clamp(0.0, maxStart)`. When a clip's duration exceeds the scene duration
// (reachable via ensureTimelineForScene, which imports a beat's durationSeconds with
// no cross-check against the timeline durationSeconds), maxStart is negative and
// `clamp(0.0, negativeUpperBound)` throws an ArgumentError on drag end, crashing the
// timeline workspace instead of clamping the clip to start at 0.

Widget _wrap({
  required double durationSeconds,
  required List<TimelineClipModel> clips,
  void Function(TimelineClipModel previous, TimelineClipModel updated)?
  onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: TimelineWorkspaceScreen(
        sceneId: 'scene-1',
        sceneTitle: 'Crash Test',
        durationSeconds: durationSeconds,
        clips: clips,
        onClipTimingChanged: onChanged == null
            ? null
            : (previous, updated) async => onChanged(previous, updated),
      ),
    ),
  );
}

Future<void> _dragClipLeft(WidgetTester tester) async {
  // Aim at the clip chip itself (its label text), then drag its GestureDetector.
  final label = find.text('Oversized beat');
  expect(label, findsOneWidget);
  final chip = find
      .ancestor(
        of: find.byType(TimelineClip),
        matching: find.byType(GestureDetector),
      )
      .first;
  expect(chip, findsOneWidget);
  final center = tester.getCenter(chip);
  final gesture = await tester.startGesture(center);
  await tester.pump();
  // Drag well past the left edge so startSeconds + delta is far below 0.
  await gesture.moveBy(const Offset(-100, 0));
  await tester.pump();
  await gesture.moveBy(const Offset(-100, 0));
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

void main() {
  testWidgets(
    'dragging a clip whose duration exceeds the scene does not throw',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Scene is 10s; the single action clip is 15s -> maxStart = -5.
      final clip = TimelineClipModel(
        id: 'clip-1',
        trackId: TimelineTrackType.action.name,
        startSeconds: 0,
        durationSeconds: 15,
        label: 'Oversized beat',
      );

      await tester.pumpWidget(_wrap(durationSeconds: 10, clips: [clip]));
      await tester.pump();
      expect(tester.takeException(), isNull);

      await _dragClipLeft(tester);

      // The defect: this surfaces the ArgumentError from clamp(0.0, -5.0).
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('oversized clip drag end clamps to a valid start of 0', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final clip = TimelineClipModel(
      id: 'clip-2',
      trackId: TimelineTrackType.action.name,
      startSeconds: 0,
      durationSeconds: 15,
      label: 'Oversized beat',
    );
    TimelineClipModel? updated;
    await tester.pumpWidget(
      _wrap(
        durationSeconds: 10,
        clips: [clip],
        onChanged: (previous, next) => updated = next,
      ),
    );
    await tester.pump();

    await _dragClipLeft(tester);

    expect(tester.takeException(), isNull);
    // The drag must have reached the callback, or the test proves nothing.
    expect(updated, isNotNull);
    // A valid result never starts below 0.
    expect(updated!.startSeconds, greaterThanOrEqualTo(0));
  });
}
