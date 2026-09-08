import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character/domain/character_model.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_controller.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_screen.dart';
import 'package:void_scriptor/features/character_mode/presentation/widgets/character_mode_section.dart';
import 'package:void_scriptor/features/character_mode/domain/loadout_slot.dart';

void main() {
  for (final section in ['Profile', 'Appearance', 'Relationships', 'Notes']) {
    testWidgets('$section owns only its relevant tools on narrow screens', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            characterWorkspaceProvider('c').overrideWith(
              (ref) async => const CharacterModel(
                assetId: 'c',
                projectId: 'p',
                displayName: 'Character',
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CharacterWorkspaceScreen(
                characterId: 'c',
                activeSection: section,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final modes = tester
          .widgetList<CharacterModeSection>(find.byType(CharacterModeSection))
          .toList();
      expect(
        modes.length,
        ['Appearance', 'Relationships'].contains(section) ? 1 : 0,
      );
      if (section == 'Appearance') {
        expect(modes.single.slots, contains(LoadoutSlot.carriedItem));
        expect(modes.single.slots, isNot(contains(LoadoutSlot.companion)));
        expect(find.text('Identity Preservation'), findsOneWidget);
      }
      if (section == 'Relationships') {
        expect(modes.single.slots, [LoadoutSlot.companion]);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
