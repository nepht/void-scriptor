import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/features/character_mode/domain/character_mode.dart';
import 'package:void_scriptor/features/character_mode/presentation/character_mode_controller.dart';
import 'package:void_scriptor/features/character_mode/presentation/widgets/character_mode_selector.dart';

void main() {
  testWidgets('mode selection publishes a CharacterModeChanged event', (
    tester,
  ) async {
    const characterId = 'character-1';
    const modes = [
      CharacterMode(
        id: 'mode-a',
        projectId: 'project-1',
        characterId: characterId,
        name: 'Base',
        isDefault: true,
      ),
      CharacterMode(
        id: 'mode-b',
        projectId: 'project-1',
        characterId: characterId,
        name: 'Combat',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CharacterModeSelector(
              characterId: characterId,
              modes: modes,
              selectedModeId: 'mode-a',
              onCreateMode: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Combat').last);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CharacterModeSelector)),
    );
    final event = container.read(characterModeChangedProvider(characterId));
    expect(event, isNotNull);
    expect(event!.previousModeId, isNull);
    expect(event.currentModeId, 'mode-b');
  });
}
