import 'package:flutter/material.dart';

/// Stage placement view (Step 35.18).
class StagePlacementView extends StatelessWidget {
  const StagePlacementView({
    super.key,
    required this.actorCount,
    required this.lightCount,
  });

  final int actorCount;
  final int lightCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Stage', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text('Actors: $actorCount'),
        Text('Lights: $lightCount'),
      ],
    );
  }
}
