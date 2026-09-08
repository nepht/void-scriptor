import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/relation_section.dart';
import '../widgets/support_relationship_section.dart';
import 'inspector_body.dart';

class CharacterInspector extends ConsumerWidget {
  const CharacterInspector({super.key, required this.characterId});
  final String characterId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      InspectorBody(name: characterId, type: 'Character', sections: const []),
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
