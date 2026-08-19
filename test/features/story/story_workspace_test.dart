import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/presentation/scene_workspace_screen.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';

void main() {
  testWidgets('story workspace and scene workspace render narrow layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: StoryWorkspaceScreen(storyId: 'story-1')),
        ),
      ),
    );
    expect(find.text('STORY STRUCTURE'), findsOneWidget);
    expect(find.text('CHAPTERS'), findsOneWidget);
    expect(find.text('SCENE EDITOR'), findsOneWidget);
    expect(find.text('Export Markdown'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Satu dua tiga');
    await tester.pump();
    expect(find.text('3 kata'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SceneWorkspaceScreen(
              sceneId: 'scene-1',
              title: 'Megacity Landing',
            ),
          ),
        ),
      ),
    );
    expect(find.text('ACTION BEATS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
