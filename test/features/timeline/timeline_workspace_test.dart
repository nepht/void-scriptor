import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
