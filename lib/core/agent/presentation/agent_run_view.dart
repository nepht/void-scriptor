import 'package:flutter/material.dart';

/// Agent run result view (Step 39.18).
class AgentRunView extends StatelessWidget {
  const AgentRunView({
    super.key,
    required this.agentName,
    required this.state,
    required this.output,
  });

  final String agentName;
  final String state;
  final String output;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(agentName, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text('State: $state'),
        Text('Output: $output'),
      ],
    );
  }
}
