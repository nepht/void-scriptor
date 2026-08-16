import 'package:flutter/material.dart';

/// Knowledge engine overview panel (Step 38.16).
class KnowledgeEnginePanel extends StatelessWidget {
  const KnowledgeEnginePanel({
    super.key,
    required this.entityCount,
    required this.relationCount,
  });

  final int entityCount;
  final int relationCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Knowledge Engine', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 12),
        Text('Entities: $entityCount'),
        Text('Relations: $relationCount'),
      ],
    );
  }
}
