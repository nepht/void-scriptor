import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/character_mode.dart';
import '../../domain/character_mode_changed.dart';
import '../character_mode_controller.dart';
import '../../data/character_mode_repository_impl.dart';
import '../../../projects/presentation/project_persistence_providers.dart';

class CharacterModeSelector extends ConsumerWidget {
  const CharacterModeSelector({
    super.key,
    required this.characterId,
    required this.modes,
    required this.selectedModeId,
    required this.onCreateMode,
  });

  final String characterId;
  final List<CharacterMode> modes;
  final String? selectedModeId;
  final VoidCallback onCreateMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveId =
        selectedModeId ??
        (modes.where((mode) => mode.isDefault).firstOrNull?.id ??
            modes.firstOrNull?.id);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('MODE'),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: effectiveId,
          hint: const Text('No mode'),
          items: [
            ...modes.map(
              (mode) =>
                  DropdownMenuItem(value: mode.id, child: Text(mode.name)),
            ),
            const DropdownMenuItem(
              value: '__create__',
              child: Text('+ Create Mode'),
            ),
          ],
          onChanged: (value) {
            if (value == '__create__') {
              onCreateMode();
              return;
            }
            if (value != null) {
              final previous = ref.read(
                selectedCharacterModeProvider(characterId),
              );
              ref
                      .read(selectedCharacterModeProvider(characterId).notifier)
                      .state =
                  value;
              ref
                  .read(characterModeChangedProvider(characterId).notifier)
                  .state = CharacterModeChanged(
                characterId: characterId,
                previousModeId: previous,
                currentModeId: value,
              );
              final session = ref.read(projectSessionProvider).valueOrNull;
              if (session != null) {
                CharacterModeRepositoryImpl(
                  session.database,
                ).rememberLastUsedMode(characterId: characterId, modeId: value);
              }
            }
          },
        ),
      ],
    );
  }
}
