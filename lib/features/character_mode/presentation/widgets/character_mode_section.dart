import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/project/project_database.dart' as db;
import '../../../../features/projects/presentation/project_persistence_providers.dart';
import '../../data/character_loadout_repository_impl.dart';
import '../../domain/character_mode.dart';
import '../../domain/loadout_slot.dart';
import '../character_mode_controller.dart';
import 'asset_picker.dart';
import 'character_mode_selector.dart';
import 'character_mode_identity_editor.dart';
import 'character_mode_references_card.dart';

const characterLoadoutEditorSlots = <LoadoutSlot>[
  LoadoutSlot.wardrobe,
  LoadoutSlot.armor,
  LoadoutSlot.primaryWeapon,
  LoadoutSlot.secondaryWeapon,
  LoadoutSlot.accessory,
  LoadoutSlot.carriedItem,
  LoadoutSlot.hairVariant,
  LoadoutSlot.companion,
  LoadoutSlot.vehicle,
];

enum LoadoutSlotChange { unchanged, remove, replace }

String loadoutAssetLabel(String? assetId, List<db.Asset> assets) {
  if (assetId == null) return 'None';
  for (final asset in assets) {
    if (asset.id == assetId) return asset.name;
  }
  return 'Unknown asset';
}

LoadoutSlotChange loadoutSlotChange({
  required LoadoutSlot slot,
  required String? originalAssetId,
  required String? selectedAssetId,
}) {
  if (originalAssetId == selectedAssetId) return LoadoutSlotChange.unchanged;
  if (selectedAssetId == null) return LoadoutSlotChange.remove;
  return LoadoutSlotChange.replace;
}

/// vs-hunt-20260913-loadout LDT-BUG-03b: the quantity stepper may only appear
/// for slots whose validator accepts quantity > 1. The old UI gate was looser
/// than the repository (`multiple` multiplicity), so tapping '+' on an
/// accessory and saving threw ArgumentError('accessory supports quantity 1
/// only'). One source of truth = validateLoadoutQuantity.
bool loadoutSlotSupportsQuantity(LoadoutSlot slot) =>
    validateLoadoutQuantity(slot, 2) == null;

class CharacterModeSection extends ConsumerWidget {
  const CharacterModeSection({
    super.key,
    required this.characterId,
    this.title,
    this.slots = characterLoadoutEditorSlots,
    this.showModeDetails = true,
  });

  final String characterId;
  final String? title;
  final List<LoadoutSlot> slots;
  final bool showModeDetails;

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
            _ModeLoadoutCard(mode: mode, title: title, slots: slots),
            if (showModeDetails) ...[
              const SizedBox(height: 10),
              CharacterModeIdentityEditor(modeId: mode.id),
              const SizedBox(height: 10),
              CharacterModeReferencesCard(modeId: mode.id),
            ],
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
  const _ModeLoadoutCard({required this.mode, required this.slots, this.title});
  final CharacterMode mode;
  final String? title;
  final List<LoadoutSlot> slots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadout = ref.watch(characterModeLoadoutProvider(mode.id));
    final assets =
        ref.watch(projectAssetsProvider).valueOrNull ?? const <db.Asset>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: loadout.when(
          loading: () => const Text('Loading loadout…'),
          error: (error, _) => Text('Loadout error: $error'),
          data: (entries) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${title?.toUpperCase() ?? 'CURRENT MODE'}: ${mode.name}'),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                const Text('No loadout entries')
              else
                ...entries
                    .where(
                      (entry) => slots.any((slot) => slot.value == entry.slot),
                    )
                    .map(
                      (entry) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(_slotLabel(entry.slot)),
                        subtitle: Text(
                          loadoutAssetLabel(entry.assetId, assets),
                        ),
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
      for (final slot in slots) slot: _entryAssetId(entries, slot),
    };
    final original = Map<LoadoutSlot, String?>.from(selected);
    final createdAssets = <db.Asset>[];
    final selectedQuantity = <LoadoutSlot, int>{
      for (final slot in slots) slot: _entryQuantity(entries, slot),
    };
    final originalQuantity = Map<LoadoutSlot, int>.from(selectedQuantity);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('EDIT LOADOUT — ${mode.name}'),
          content: SizedBox(
            width: 440,
            height: 460,
            child: ListView(
              children: [
                for (final slot in selected.keys)
                  ListTile(
                    title: Text(_slotLabel(slot.value)),
                    subtitle: Text(
                      loadoutAssetLabel(selected[slot], [
                        ...assets,
                        ...createdAssets,
                      ]),
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        if (_slotSupportsQuantity(slot))
                          _QuantityStepper(
                            key: Key('quantity-stepper-${slot.value}'),
                            quantity: selectedQuantity[slot] ?? 1,
                            onChanged: (value) =>
                                setState(() => selectedQuantity[slot] = value),
                          ),
                        if (selected[slot] != null)
                          TextButton(
                            onPressed: () =>
                                setState(() => selected[slot] = null),
                            child: const Text('Clear'),
                          ),
                        TextButton(
                          onPressed: () async {
                            final type = slot.assetType;
                            final asset = await showDialog<dynamic>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Choose ${_slotLabel(slot.value)}'),
                                content: AssetPicker(
                                  assets: [
                                    for (final asset in assets)
                                      if (!createdAssets.any(
                                        (created) => created.id == asset.id,
                                      ))
                                        asset,
                                    ...createdAssets,
                                  ],
                                  assetType: type,
                                  initialAssetId: selected[slot],
                                  onCreate:
                                      type == 'armor' ||
                                          type == 'accessory' ||
                                          type == 'hair_variant' ||
                                          type == 'prop' ||
                                          type == 'creature' ||
                                          type == 'vehicle'
                                      ? () => _createAsset(context, ref, type)
                                      : null,
                                  onSelected: (asset) =>
                                      Navigator.pop(context, asset),
                                ),
                              ),
                            );
                            if (asset != null) {
                              setState(() {
                                selected[slot] = asset.id;
                                createdAssets.add(asset);
                              });
                            }
                          },
                          child: const Text('Choose'),
                        ),
                      ],
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
                  final slot = entry.key;
                  final assetId = entry.value;
                  final originalAssetId = original[slot];
                  final change = loadoutSlotChange(
                    slot: slot,
                    originalAssetId: originalAssetId,
                    selectedAssetId: assetId,
                  );
                  if (change == LoadoutSlotChange.remove &&
                      originalAssetId != null) {
                    await actions.removeSlot(
                      modeId: mode.id,
                      slot: slot,
                      assetId: originalAssetId,
                    );
                  } else if (change == LoadoutSlotChange.replace &&
                      assetId != null) {
                    await actions.setSlot(
                      modeId: mode.id,
                      slot: slot,
                      assetId: assetId,
                      quantity: selectedQuantity[slot] ?? 1,
                    );
                  } else if (change == LoadoutSlotChange.unchanged &&
                      originalAssetId != null &&
                      (selectedQuantity[slot] ?? 1) !=
                          (originalQuantity[slot] ?? 1)) {
                    final session = ref
                        .read(projectSessionProvider)
                        .valueOrNull;
                    if (session != null) {
                      await CharacterLoadoutRepositoryImpl(
                        session.database,
                      ).updateQuantity(
                        modeId: mode.id,
                        slotValue: slot.value,
                        assetId: originalAssetId,
                        quantity: selectedQuantity[slot] ?? 1,
                      );
                    }
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

  int _entryQuantity(List<dynamic> entries, LoadoutSlot slot) {
    for (final entry in entries) {
      if (entry.slot == slot.value) return (entry.quantity as int?) ?? 1;
    }
    return 1;
  }

  bool _slotSupportsQuantity(LoadoutSlot slot) =>
      loadoutSlotSupportsQuantity(slot);

  Future<db.Asset?> _createAsset(
    BuildContext context,
    WidgetRef ref,
    String type,
  ) async {
    var name = '';
    var description = '';
    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(switch (type) {
          'prop' => 'Create Story Item',
          'armor' => 'Create Armor',
          'creature' => 'Create Creature',
          'vehicle' => 'Create Vehicle',
          _ => 'Create Asset',
        }),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (value) => name = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (value) => description = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (shouldCreate != true || name.trim().isEmpty) return null;
    return CharacterModeActions(
      ref,
    ).createStandaloneAsset(name: name, description: description, type: type);
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
  });

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: 'Decrease quantity',
        onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
        icon: const Icon(Icons.remove_circle_outline, size: 20),
      ),
      Text('$quantity'),
      IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: 'Increase quantity',
        onPressed: quantity < 99 ? () => onChanged(quantity + 1) : null,
        icon: const Icon(Icons.add_circle_outline, size: 20),
      ),
    ],
  );
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
