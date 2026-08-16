import 'package:flutter/material.dart';

/// Agent platform overview panel (Step 39.16).
class AgentPlatformPanel extends StatelessWidget {
  const AgentPlatformPanel({
    super.key,
    required this.agentCount,
    required this.runningCount,
  });

  final int agentCount;
  final int runningCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AI Agents', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 12),
        Text('Agents: $agentCount'),
        Text('Running: $runningCount'),
      ],
    );
  }
}
