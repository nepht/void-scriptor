import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character/domain/character_model.dart';
import 'package:void_scriptor/features/character/presentation/character_controller.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_controller.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_screen.dart';

void main() {
  test('selectedCharacterIdProvider starts without a selection', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(selectedCharacterIdProvider), isNull);
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
    expect(find.text('Character Identity'), findsOneWidget);
    expect(find.text('Turnaround'), findsOneWidget);
    expect(find.text('Silhouette'), findsOneWidget);
    expect(find.text('Color Palette'), findsOneWidget);
    expect(find.text('Accessories'), findsOneWidget);
    expect(find.text('Identity Preservation'), findsOneWidget);
    expect(find.text('Primary References'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
    expect(find.text('Character Identity'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
