import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/relation_section.dart';
import 'inspector_body.dart';

class CharacterInspector extends ConsumerWidget {
  const CharacterInspector({super.key, required this.characterId});
  final String characterId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      InspectorBody(
        name: characterId,
        type: 'Character',
        sections: const [
          'Properties',
          'Identity',
          'Tags',
          'AI Context',
          'History',
        ],
      ),
      RelationSection(assetId: characterId),
    ],
  );
}
