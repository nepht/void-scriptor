import 'package:flutter/material.dart';

/// Virtual production overview panel (Step 35.16).
class VirtualProductionPanel extends StatelessWidget {
  const VirtualProductionPanel({
    super.key,
    required this.shotCount,
    required this.takeCount,
    required this.totalDurationSeconds,
  });

  final int shotCount;
  final int takeCount;
  final double totalDurationSeconds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Virtual Production', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 12),
        Text('Shots: $shotCount'),
        Text('Takes: $takeCount'),
        Text('Total duration: ${totalDurationSeconds.toStringAsFixed(1)}s'),
      ],
    );
  }
}
