import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/character_mode.dart';
import '../../domain/loadout_slot.dart';
import '../character_mode_controller.dart';
import 'asset_picker.dart';
import 'character_mode_selector.dart';
import 'character_mode_identity_editor.dart';
import 'character_mode_references_card.dart';

class CharacterModeSection extends ConsumerWidget {
  const CharacterModeSection({super.key, required this.characterId});

  final String characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modes = ref.watch(characterModesProvider(characterId));
    return modes.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('Mode error: $error'),
      data: (items) {
        final selectedId = ref.watch(
          selectedCharacterModeProvider(characterId),
        );
        final lastUsedId = ref
            .watch(lastUsedCharacterModeProvider(characterId))
            .valueOrNull;
        final mode = _resolveMode(items, selectedId ?? lastUsedId);
        if (mode == null) {
          return _EmptyModeState(onCreate: () => _createMode(context, ref));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CharacterModeSelector(
              characterId: characterId,
              modes: items,
              selectedModeId: mode.id,
              onCreateMode: () => _createMode(context, ref),
            ),
            const SizedBox(height: 10),
            _ModeLoadoutCard(mode: mode),
            const SizedBox(height: 10),
            CharacterModeIdentityEditor(modeId: mode.id),
            const SizedBox(height: 10),
            CharacterModeReferencesCard(modeId: mode.id),
          ],
        );
      },
    );
  }

  CharacterMode? _resolveMode(List<CharacterMode> modes, String? selectedId) {
    if (modes.isEmpty) return null;
    for (final mode in modes) {
      if (mode.id == selectedId) return mode;
    }
    for (final mode in modes) {
      if (mode.isDefault) return mode;
    }
    return modes.first;
  }

  Future<void> _createMode(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Character Mode'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Mode name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !context.mounted) return;
    await CharacterModeActions(
      ref,
    ).create(characterId: characterId, name: name);
  }
}

class _ModeLoadoutCard extends ConsumerWidget {
  const _ModeLoadoutCard({required this.mode});
  final CharacterMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadout = ref.watch(characterModeLoadoutProvider(mode.id));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: loadout.when(
          loading: () => const Text('Loading loadout…'),
          error: (error, _) => Text('Loadout error: $error'),
          data: (entries) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CURRENT MODE: ${mode.name}'),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                const Text('No loadout entries')
              else
                ...entries.map(
                  (entry) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(_slotLabel(entry.slot)),
                    subtitle: Text(entry.assetId),
                    trailing: entry.enabled
                        ? const Icon(Icons.check_circle_outline)
                        : const Icon(Icons.visibility_off_outlined),
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => _editLoadout(context, ref, entries),
                  child: const Text('Edit Loadout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _slotLabel(String value) => value.replaceAll('_', ' ');

  Future<void> _editLoadout(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> entries,
  ) async {
    final assets = await ref.read(projectAssetsProvider.future);
    if (!context.mounted) return;
    final selected = <LoadoutSlot, String?>{
      for (final slot in [
        LoadoutSlot.wardrobe,
        LoadoutSlot.primaryWeapon,
        LoadoutSlot.secondaryWeapon,
        LoadoutSlot.accessory,
        LoadoutSlot.hairVariant,
        LoadoutSlot.companion,
        LoadoutSlot.vehicle,
      ])
        slot: _entryAssetId(entries, slot),
    };
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('EDIT LOADOUT — ${mode.name}'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final slot in selected.keys)
                  ListTile(
                    title: Text(_slotLabel(slot.value)),
                    subtitle: Text(selected[slot] ?? 'None'),
                    trailing: TextButton(
                      onPressed: () async {
                        final type = slot.assetType;
                        final asset = await showDialog<dynamic>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Choose ${_slotLabel(slot.value)}'),
                            content: AssetPicker(
                              assets: assets,
                              assetType: type,
                              initialAssetId: selected[slot],
                              onSelected: (asset) =>
                                  Navigator.pop(context, asset),
                            ),
                          ),
                        );
                        if (asset != null) {
                          setState(() => selected[slot] = asset.id);
                        }
                      },
                      child: const Text('Choose'),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final actions = CharacterModeActions(ref);
                for (final entry in selected.entries) {
                  final assetId = entry.value;
                  if (assetId != null) {
                    await actions.setSlot(
                      modeId: mode.id,
                      slot: entry.key,
                      assetId: assetId,
                    );
                  }
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save Loadout'),
            ),
          ],
        ),
      ),
    );
  }

  String? _entryAssetId(List<dynamic> entries, LoadoutSlot slot) {
    for (final entry in entries) {
      if (entry.slot == slot.value) return entry.assetId as String;
    }
    return null;
  }
}

class _EmptyModeState extends StatelessWidget {
  const _EmptyModeState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: const Text('No Character Mode'),
      subtitle: const Text('Create a mode to configure this character.'),
      trailing: FilledButton(
        onPressed: onCreate,
        child: const Text('Create Mode'),
      ),
    ),
  );
}
