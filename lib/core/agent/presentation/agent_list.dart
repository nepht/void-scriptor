import 'package:flutter/material.dart';

/// Agent list (Step 39.17).
class AgentList extends StatelessWidget {
  const AgentList({super.key, required this.agents});

  final List<String> agents;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final agent in agents)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(agent),
          ),
      ],
    );
  }
}
