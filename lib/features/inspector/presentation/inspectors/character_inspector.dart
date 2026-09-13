import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../projects/presentation/project_persistence_providers.dart';
import '../widgets/relation_section.dart';
import '../widgets/support_relationship_section.dart';
import 'inspector_body.dart';

/// vs-hunt-20260913-inspector INS-BUG-01: resolve the character's real
/// display name instead of surfacing the raw UUID token in InspectorBody.
/// Mirrors Wardrobe/Weapon inspectors: read through the active session,
/// null (loading / missing asset) falls back to 'Unknown asset' — never
/// the id, per the loadout UX contract.
final characterInspectorNameProvider = FutureProvider.family<String?, String>((
  ref,
  characterId,
) async {
  final session = ref.watch(projectSessionProvider).valueOrNull;
  if (session == null) return null;
  final asset = await session.database.assetDao.getById(characterId);
  if (asset == null) return null;
  return asset.name;
});

class CharacterInspector extends ConsumerWidget {
  const CharacterInspector({super.key, required this.characterId});
  final String characterId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      InspectorBody(
        name:
            ref
                .watch(characterInspectorNameProvider(characterId))
                .valueOrNull ??
            'Unknown asset',
        type: 'Character',
        sections: const [],
      ),
      const Text(
        'Edit character details in the workspace. Related assets are shown below.',
      ),
      const SizedBox(height: 16),
      RelationSection(assetId: characterId),
      const SizedBox(height: 16),
      SupportRelationshipSection(assetId: characterId),
    ],
  );
}
