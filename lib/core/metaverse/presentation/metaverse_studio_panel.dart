import 'package:flutter/material.dart';

/// Metaverse studio overview panel (Step 42.16).
class MetaverseStudioPanel extends StatelessWidget {
  const MetaverseStudioPanel({
    super.key,
    required this.worldCount,
    required this.zoneCount,
  });

  final int worldCount;
  final int zoneCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Metaverse Studio', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 12),
        Text('Worlds: $worldCount'),
        Text('Zones: $zoneCount'),
      ],
    );
  }
}
