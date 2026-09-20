import 'package:flutter/material.dart';

import '../widgets/reference_inspector_panel.dart';

/// Character abilities have no persisted domain collection yet. This inspector
/// preserves the requested reference composition without inventing records.
class AbilityInspector extends StatelessWidget {
  const AbilityInspector({super.key, required this.characterId});
  final String characterId;

  @override
  Widget build(BuildContext context) => ReferenceInspectorPanel(
    properties: [
      const InspectorProperty('Type', 'Ability'),
      InspectorProperty('Character ID', characterId),
      const InspectorProperty('Status', 'Not configured'),
    ],
    quickNotes: 'Character abilities require a canonical ability model.',
    linkedAssets: const [
      InspectorAssetCount('Abilities', '—', Icons.auto_awesome_outlined),
      InspectorAssetCount('References', '—', Icons.description_outlined),
    ],
  );
}
