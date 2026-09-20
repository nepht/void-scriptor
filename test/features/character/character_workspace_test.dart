import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character/domain/character_model.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_controller.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_screen.dart';
import 'package:void_scriptor/features/inspector/presentation/widgets/relation_section.dart';
import 'package:void_scriptor/features/inspector/presentation/widgets/support_relationship_section.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';

void main() {
  test('selectedCharacterIdProvider starts without a selection', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(selectionProvider), isNull);
  });

  testWidgets('character workspace renders desktop identity sections', (
    tester,
  ) async {
    const character = CharacterModel(
      assetId: 'qowner-1',
      projectId: 'project-1',
      displayName: 'Qowner',
      alias: 'Void Scriptor',
      age: 24,
      heightCm: 185,
      hair: 'White / Lavender',
      eyes: 'Violet',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterWorkspaceProvider(
            'qowner-1',
          ).overrideWith((ref) async => character),
        ],
        child: const MaterialApp(
          home: SizedBox(
            width: 1280,
            height: 900,
            child: CharacterWorkspaceScreen(characterId: 'qowner-1'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Qowner'), findsWidgets);
    expect(find.text('CHARACTER CONCEPT'), findsOneWidget);
    expect(find.text('Turnaround'), findsOneWidget);
    expect(find.text('Silhouette'), findsOneWidget);
    expect(find.text('Color Palette'), findsOneWidget);
    expect(find.text('Accessories'), findsOneWidget);
    expect(find.text('Identity Preservation'), findsNothing);
    expect(find.text('Primary References'), findsNothing);
    expect(find.text('Character Relationships'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('character sheet exposes reference navigation', (tester) async {
    const character = CharacterModel(
      assetId: 'qowner-1',
      projectId: 'project-1',
      displayName: 'Qowner',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterWorkspaceProvider(
            'qowner-1',
          ).overrideWith((ref) async => character),
        ],
        child: const MaterialApp(
          home: SizedBox(
            width: 1280,
            height: 900,
            child: CharacterWorkspaceScreen(
              characterId: 'qowner-1',
              activeSection: 'Character Sheet',
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    for (final label in [
      'Design Sheet',
      'Turnaround',
      'Silhouette',
      'Portrait',
      'Expression Reference',
      'Pose',
      'Details',
    ]) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy capabilities remain available in canonical sections', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const character = CharacterModel(
      assetId: 'qowner-1',
      projectId: 'project-1',
      displayName: 'Qowner',
    );

    Future<void> pumpSection(String section) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            characterWorkspaceProvider(
              'qowner-1',
            ).overrideWith((ref) async => character),
          ],
          child: MaterialApp(
            home: SizedBox(
              width: 1280,
              height: 1200,
              child: CharacterWorkspaceScreen(
                characterId: 'qowner-1',
                activeSection: section,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    await pumpSection('Story');
    expect(find.text('Narrative Assignment'), findsOneWidget);

    await pumpSection('AI Assets');
    expect(find.text('Ekstraksi ciri dari naskah'), findsOneWidget);

    await pumpSection('Character Sheet');
    await tester.tap(find.text('Details'));
    await tester.pump();
    expect(find.text('Primary References'), findsOneWidget);
  });

  testWidgets('relations owns relation and support capabilities', (
    tester,
  ) async {
    const character = CharacterModel(
      assetId: 'qowner-1',
      projectId: 'project-1',
      displayName: 'Qowner',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterWorkspaceProvider(
            'qowner-1',
          ).overrideWith((ref) async => character),
        ],
        child: const MaterialApp(
          home: SizedBox(
            width: 1280,
            height: 1200,
            child: CharacterWorkspaceScreen(
              characterId: 'qowner-1',
              activeSection: 'Relations',
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(RelationSection), findsOneWidget);
    expect(find.byType(SupportRelationshipSection), findsOneWidget);
  });

  testWidgets(
    'canonical sections accept future content without shell rewrites',
    (tester) async {
      const character = CharacterModel(
        assetId: 'qowner-1',
        projectId: 'project-1',
        displayName: 'Qowner',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            characterWorkspaceProvider(
              'qowner-1',
            ).overrideWith((ref) async => character),
          ],
          child: MaterialApp(
            home: SizedBox(
              width: 1280,
              height: 900,
              child: CharacterWorkspaceScreen(
                characterId: 'qowner-1',
                activeSection: 'Timeline',
                sectionBuilders: {
                  'Timeline': (context) => const Text('Custom timeline body'),
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Custom timeline body'), findsOneWidget);
    },
  );

  testWidgets('character workspace shows empty state on narrow screens', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterWorkspaceProvider(
            'missing',
          ).overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          home: SizedBox(
            width: 390,
            height: 844,
            child: CharacterWorkspaceScreen(characterId: 'missing'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No Character Selected'), findsOneWidget);
    expect(find.text('CHARACTER CONCEPT'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'character workspace renders populated data without narrow overflow',
    (tester) async {
      const character = CharacterModel(
        assetId: 'qowner-1',
        projectId: 'project-1',
        displayName: 'Qowner with an intentionally long display name',
        alias: 'Void Scriptor with an intentionally long alias',
        age: 24,
        heightCm: 185,
        hair: 'White and lavender with a very long descriptive value',
        eyes: 'Violet',
      );
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            characterWorkspaceProvider(
              'qowner-1',
            ).overrideWith((ref) async => character),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CharacterWorkspaceScreen(characterId: 'qowner-1'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(character.displayName), findsWidgets);
      expect(find.text('CHARACTER CONCEPT'), findsOneWidget);
      expect(find.text('Primary References'), findsNothing);
      expect(find.text('Identity Preservation'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
