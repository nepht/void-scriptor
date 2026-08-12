import 'package:flutter/material.dart';

import 'inspector_body.dart';

class CharacterInspector extends StatelessWidget {
  const CharacterInspector({super.key, required this.characterId});
  final String characterId;
  @override
  Widget build(BuildContext context) => InspectorBody(
    name: characterId,
    type: 'Character',
    sections: const [
      'Properties',
      'Identity',
      'Tags',
      'Relations',
      'AI Context',
      'History',
    ],
  );
}
