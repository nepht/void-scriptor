import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

void main() {
  testWidgets('Planning retains live chapter controls', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StoryWorkspaceScreen(
          storyId: 'story-1',
          activeSection: 'Planning',
        ),
      ),
    );
    expect(find.text('CHAPTERS'), findsOneWidget);
    expect(find.text('SCENE EDITOR'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('novel section shows only its relevant workspace content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StoryWorkspaceScreen(storyId: 'story-1', activeSection: 'Export'),
      ),
    );

    expect(find.text('EXPORT NOVEL'), findsOneWidget);
    expect(find.text('Export Markdown'), findsOneWidget);
    expect(find.text('SCENE EDITOR'), findsNothing);
    expect(find.text('CHAPTERS'), findsNothing);
  });

  testWidgets('lore links can return directly to the manuscript', (
    tester,
  ) async {
    String? requestedSection;
    await tester.pumpWidget(
      MaterialApp(
        home: StoryWorkspaceScreen(
          storyId: 'story-1',
          activeSection: 'Lore Links',
          onSectionRequested: (section) => requestedSection = section,
        ),
      ),
    );

    await tester.tap(find.text('Open Manuscript'));
    expect(requestedSection, 'Manuscript');
  });

  testWidgets('worldbuilding section filters unrelated collections', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: WorldbuildingBody(activeSection: 'Factions')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Factions'), findsWidgets);
    expect(find.text('Timeline'), findsNothing);
    expect(find.text('Lore Notes'), findsNothing);
    expect(find.text('Relationship Map'), findsNothing);
  });
}
