import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character/presentation/character_controller.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace.dart';

void main() {
  testWidgets('character workspace renders empty state without exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterControllerProvider(
            'project-1',
          ).overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: CharacterWorkspace(projectId: 'project-1'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No Characters Yet'), findsOneWidget);
    expect(find.text('Create Character'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
