import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../projects/presentation/project_persistence_providers.dart';
import '../character_mode_controller.dart';
import '../../data/character_mode_reference_repository.dart';

class CharacterModeReferencesCard extends ConsumerWidget {
  const CharacterModeReferencesCard({super.key, required this.modeId});
  final String modeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(projectSessionProvider).valueOrNull;
    if (session == null) return const SizedBox.shrink();
    ref.watch(projectAssetsProvider);
    final repository = CharacterModeReferenceRepository(session.database);
    return FutureBuilder(
      future: repository.getReferences(modeId),
      builder: (context, snapshot) {
        final references = snapshot.data ?? const [];
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: const Text('MODE REFERENCES'),
                subtitle: Text('${references.length} references'),
                trailing: IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  tooltip: 'Add mode reference',
                  onPressed: () => _add(context, repository, ref),
                ),
              ),
              for (final reference in references)
                ListTile(
                  dense: true,
                  title: Text(reference.referenceType),
                  subtitle: Text(reference.filePath),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await repository.remove(reference.id);
                      ref.invalidate(projectAssetsProvider);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _add(
    BuildContext context,
    CharacterModeReferenceRepository repository,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final path = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Mode Reference'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'File path'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (path == null || path.isEmpty) return;
    await repository.add(
      modeId: modeId,
      referenceType: 'custom',
      filePath: path,
    );
    ref.invalidate(projectAssetsProvider);
  }
}
