import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/typography/void_typography.dart';
import '../domain/character_model.dart';
import 'character_controller.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class CharacterWorkspace extends ConsumerWidget {
  const CharacterWorkspace({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characters = ref.watch(characterControllerProvider(projectId));
    final selectedId = ref.watch(selectedAssetProvider);
    final selected = characters.valueOrNull
        ?.where((item) => item.assetId == selectedId)
        .firstOrNull;

    return Column(
      children: [
        const _CharacterHeader(),
        Expanded(
          child: characters.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (items) => items.isEmpty
                ? _EmptyCharacterState(
                    onCreate: () => _showCreateDialog(context, ref, projectId),
                  )
                : _CharacterSheet(character: selected ?? items.first),
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateDialog(
    BuildContext context,
    WidgetRef ref,
    String projectId,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Character'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
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
    if (name == null || name.isEmpty) return;
    final session = ref.read(projectSessionProvider).valueOrNull;
    if (session == null) return;
    await CharacterActions(ref, projectId, session.database).create(name);
  }
}

class _CharacterHeader extends StatelessWidget {
  const _CharacterHeader();

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    color: context.palette.panelSecondary,
    child: const Row(
      children: [
        Text('Void Universe', style: VoidTypography.title),
        SizedBox(width: 10),
        Text('/', style: VoidTypography.caption),
        SizedBox(width: 10),
        Text('Characters', style: VoidTypography.caption),
      ],
    ),
  );
}

class _EmptyCharacterState extends StatelessWidget {
  const _EmptyCharacterState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
         Icon(
          Icons.person_add_alt_1_outlined,
          size: 42,
          color: context.palette.textMuted,
        ),
        const SizedBox(height: 14),
        const Text('No Characters Yet', style: VoidTypography.headingMedium),
        const SizedBox(height: 8),
        const Text(
          'Create the first character in this universe.',
          style: VoidTypography.caption,
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: const Text('Create Character'),
        ),
      ],
    ),
  );
}

class _CharacterSheet extends StatelessWidget {
  const _CharacterSheet({required this.character});
  final CharacterModel character;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 860),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 220,
            height: 280,
            decoration: BoxDecoration(
              color: context.palette.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child:  Icon(
              Icons.person_outline,
              size: 72,
              color: context.palette.textMuted,
            ),
          ),
          const SizedBox(width: 26),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.displayName,
                  style: VoidTypography.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  character.alias.isEmpty ? 'Character' : character.alias,
                  style: VoidTypography.body,
                ),
                const SizedBox(height: 26),
                const Text('CHARACTER IDENTITY', style: VoidTypography.caption),
                const SizedBox(height: 12),
                _Property(
                  label: 'Hair',
                  value: character.hair.isEmpty ? '—' : character.hair,
                ),
                _Property(
                  label: 'Eyes',
                  value: character.eyes.isEmpty ? '—' : character.eyes,
                ),
                _Property(
                  label: 'Height',
                  value: character.heightCm == null
                      ? '—'
                      : '${character.heightCm} cm',
                ),
                const SizedBox(height: 22),
                const Text(
                  'IDENTITY PRESERVATION',
                  style: VoidTypography.caption,
                ),
                const SizedBox(height: 8),
                const _LockRow(label: 'Face Lock'),
                const _LockRow(label: 'Hair Lock'),
                const _LockRow(label: 'Body Lock'),
                const _LockRow(label: 'Color Lock'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Property extends StatelessWidget {
  const _Property({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: VoidTypography.caption)),
        Text(value, style: VoidTypography.body),
      ],
    ),
  );
}

class _LockRow extends StatelessWidget {
  const _LockRow({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 120, child: Text(label, style: VoidTypography.body)),
      const Icon(Icons.circle, size: 10, color: Colors.green),
    ],
  );
}
