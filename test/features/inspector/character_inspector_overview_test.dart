import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character/domain/character_identity_profile.dart';
import 'package:void_scriptor/features/character/domain/character_model.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_controller.dart';
import 'package:void_scriptor/features/inspector/presentation/inspectors/character_inspector.dart';

void main() {
  testWidgets('character inspector renders available character data honestly', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const character = CharacterModel(
      assetId: 'char-1',
      projectId: 'project-1',
      displayName: 'Qowner',
      alias: 'Quiz Maker of Void',
      biography: 'Protagonis utama.',
      gender: 'Male',
      age: 24,
      heightCm: 185,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterWorkspaceProvider(
            'char-1',
          ).overrideWith((ref) async => character),
          characterIdentityProvider('char-1').overrideWith(
            (ref) async => const CharacterIdentityProfile(
              characterId: 'char-1',
              notes: 'Catatan kontinuitas karakter.',
              outfitLock: true,
            ),
          ),
          characterInspectorDetailsProvider('char-1').overrideWith(
            (ref) async => CharacterInspectorDetails(
              version: '2.3.0',
              createdAt: DateTime.utc(2026, 1, 2),
              updatedAt: DateTime.utc(2026, 9, 20),
              tags: const ['canon', 'main-character'],
              referenceCount: 3,
              versions: const ['Current Canon', 'Updated Wardrobe'],
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 4000,
              child: CharacterInspector(characterId: 'char-1'),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Qowner'), findsOneWidget);
    expect(find.text('char-1'), findsNothing);
    expect(find.text('Quiz Maker of Void'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('185 cm'), findsOneWidget);
    expect(find.text('Catatan kontinuitas karakter.'), findsOneWidget);
    expect(find.text('canon'), findsOneWidget);
    expect(find.text('main-character'), findsOneWidget);
    expect(find.text('2.3.0'), findsOneWidget);
    expect(find.text('2026-01-02'), findsOneWidget);
    expect(find.text('2026-09-20'), findsOneWidget);
    expect(find.text('Face Lock'), findsOneWidget);
    expect(find.text('Wardrobe Lock'), findsOneWidget);
    expect(find.text('References'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('VERSION HISTORY'), findsOneWidget);
    expect(find.text('Current Canon'), findsOneWidget);
    expect(find.text('Updated Wardrobe'), findsOneWidget);
    expect(find.text('—'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
