import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/timeline/domain/timeline_model.dart';
import 'package:void_scriptor/features/timeline/presentation/timeline_workspace_screen.dart';

void main() {
  testWidgets('timeline workspace renders tracks and mobile controls', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TimelineWorkspaceScreen(
            sceneId: 'scene-1',
            sceneTitle: 'Megacity Landing',
            durationSeconds: 10,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Megacity Landing'), findsOneWidget);
    expect(find.text('Character'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Action'), findsOneWidget);
    expect(find.text('Fit Scene'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('timeline drag commits one position delta command', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final changes = <(TimelineClipModel, TimelineClipModel)>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimelineWorkspaceScreen(
            sceneId: 'scene-1',
            sceneTitle: 'Landing',
            durationSeconds: 10,
            clips: const [
              TimelineClipModel(
                id: 'clip-1',
                trackId: 'action',
                startSeconds: 0,
                durationSeconds: 2,
                label: 'Descend',
              ),
            ],
            onClipTimingChanged: (previous, updated) async {
              changes.add((previous, updated));
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.drag(find.text('Descend'), const Offset(80, 0));
    await tester.pump();

    expect(changes, hasLength(1));
    expect(changes.single.$1.startSeconds, 0);
    expect(changes.single.$2.startSeconds, 1);
  });
}
