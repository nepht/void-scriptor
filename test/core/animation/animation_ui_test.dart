import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/animation/presentation/animation_preview_panel.dart';
import 'package:void_scriptor/core/animation/presentation/animation_timeline_view.dart';
import 'package:void_scriptor/core/animation/presentation/playback_controls.dart';

void main() {
  testWidgets('AnimationPreviewPanel shows time and stats', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimationPreviewPanel(
            currentTime: 1.5,
            durationSeconds: 2.0,
            trackCount: 3,
          ),
        ),
      ),
    );
    expect(find.text('Animation Preview'), findsOneWidget);
    expect(find.textContaining('1.5'), findsWidgets);
    expect(find.textContaining('3'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AnimationTimelineView renders track rows', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AnimationTimelineView(trackNames: ['x', 'y'])),
      ),
    );
    expect(find.text('x'), findsOneWidget);
    expect(find.text('y'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PlaybackControls calls callbacks', (tester) async {
    var played = false;
    var paused = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaybackControls(
            onPlay: () => played = true,
            onPause: () => paused = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.play_arrow));
    expect(played, isTrue);
    await tester.tap(find.byIcon(Icons.pause));
    expect(paused, isTrue);
    expect(tester.takeException(), isNull);
  });
}
