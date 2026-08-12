import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors/void_colors.dart';
import '../../../design_system/typography/void_typography.dart';
import '../../character/presentation/character_controller.dart';
import '../../character/domain/character_model.dart';
import '../../projects/presentation/project_persistence_providers.dart';

class InspectorPanel extends ConsumerWidget {
  const InspectorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref
        .watch(projectSessionProvider)
        .valueOrNull
        ?.manifest
        .id;
    final selectedId = ref.watch(selectedAssetProvider);
    final characters = projectId == null
        ? const AsyncValue<List<CharacterModel>>.data([])
        : ref.watch(characterControllerProvider(projectId));
    final selected = characters.valueOrNull
        ?.where((item) => item.assetId == selectedId)
        .firstOrNull;

    return Container(
      width: 310,
      decoration: const BoxDecoration(
        color: VoidColors.panel,
        border: Border(left: BorderSide(color: VoidColors.borderSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InspectorHeader(),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: selected == null
                  ? const _NoSelection()
                  : _CharacterInspector(character: selected),
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorHeader extends StatelessWidget {
  const _InspectorHeader();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 44,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Text(
            'INSPECTOR',
            style: TextStyle(
              color: VoidColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          Spacer(),
          Icon(Icons.more_horiz, size: 17, color: VoidColors.textMuted),
        ],
      ),
    ),
  );
}

class _NoSelection extends StatelessWidget {
  const _NoSelection();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16),
    child: Text(
      'No selection',
      style: TextStyle(color: VoidColors.textMuted, fontSize: 11),
    ),
  );
}

class _CharacterInspector extends StatelessWidget {
  const _CharacterInspector({required this.character});
  final CharacterModel character;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(character.displayName, style: VoidTypography.title),
        const SizedBox(height: 4),
        const Text('Character', style: VoidTypography.caption),
        const SizedBox(height: 24),
        const Text('Properties', style: VoidTypography.title),
        const SizedBox(height: 10),
        _Line(label: 'Name', value: character.displayName),
        _Line(
          label: 'Alias',
          value: character.alias.isEmpty ? '—' : character.alias,
        ),
        _Line(
          label: 'Height',
          value: character.heightCm == null ? '—' : '${character.heightCm} cm',
        ),
        const SizedBox(height: 22),
        const Text('Identity', style: VoidTypography.title),
        const SizedBox(height: 8),
        const _Lock(label: 'Face Lock'),
        const _Lock(label: 'Hair Lock'),
        const _Lock(label: 'Body Lock'),
        const _Lock(label: 'Color Lock'),
        const SizedBox(height: 22),
        const Text('Tags', style: VoidTypography.title),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            Chip(
              label: Text(
                character.hair.isEmpty ? 'character' : character.hair,
              ),
            ),
            const Chip(label: Text('asset')),
          ],
        ),
      ],
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label, style: VoidTypography.caption)),
        Text(value, style: VoidTypography.body),
      ],
    ),
  );
}

class _Lock extends StatelessWidget {
  const _Lock({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label, style: VoidTypography.body)),
        const Text(
          'ON',
          style: TextStyle(
            color: Colors.green,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
