import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspaces/domain/novel_character_link.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_projection_cache.dart';
import 'package:void_scriptor/features/workspaces/presentation/workspace_projection_card.dart';

void main() {
  testWidgets('renders linked character projections without narrow overflow', (
    tester,
  ) async {
    final projection = WorkspaceProjection(
      novelWorkspaceId: 'novel-1',
      links: [
        NovelCharacterLink.create(
          linkId: 'link-1',
          novelWorkspaceId: 'novel-1',
          characterWorkspaceId: 'character-1',
          characterId: 'character-1',
          role: 'protagonist',
          visibility: 'visible',
          now: DateTime.utc(2026, 8, 22),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkspaceProjectionCard(
            projectionFuture: Future.value(projection),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Linked Characters'), findsOneWidget);
    expect(find.text('character-1 · protagonist'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders an honest empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkspaceProjectionCard(
            projectionFuture: Future.value(
              const WorkspaceProjection(novelWorkspaceId: 'novel-1', links: []),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No linked characters'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
