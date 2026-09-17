import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';

void main() {
  testWidgets(
    '112.32 exposes planning, drafting, snapshot, and export workflow screens',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Future<void> pumpSection(String? section) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StoryWorkspaceScreen(
                storyId: 'writer-workflow-story',
                activeSection: section,
              ),
            ),
          ),
        );
        await tester.pump();
      }

      await pumpSection('Planning');
      expect(find.text('Planning'), findsOneWidget);
      expect(find.text('STORY STRUCTURE'), findsOneWidget);
      expect(find.text('CHAPTERS'), findsOneWidget);

      await pumpSection('Manuscript');
      expect(find.text('SCENE EDITOR'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await pumpSection('Versions');
      expect(find.text('SCENE SNAPSHOTS'), findsOneWidget);
      expect(find.text('Belum ada session project aktif.'), findsOneWidget);

      await pumpSection('Export');
      expect(find.text('EXPORT NOVEL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
