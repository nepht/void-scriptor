import 'package:flutter/material.dart';

import '../../../core/agent/presentation/agent_platform_panel.dart';
import '../../../core/enterprise/presentation/studio_management_panel.dart';

/// Integrated studio control surface for governance, agents, tasks, and mode.
class StudioCommandCenter extends StatelessWidget {
  const StudioCommandCenter({
    super.key,
    required this.studioName,
    required this.plan,
    required this.usedSeats,
    required this.maxSeats,
    required this.agentCount,
    required this.runningCount,
    required this.taskCount,
    required this.activeMode,
  });

  final String studioName;
  final String plan;
  final int usedSeats;
  final int maxSeats;
  final int agentCount;
  final int runningCount;
  final int taskCount;
  final String activeMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('STUDIO COMMAND CENTER')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StudioManagementPanel(
            studioName: studioName,
            plan: plan,
            usedSeats: usedSeats,
            maxSeats: maxSeats,
          ),
          const SizedBox(height: 24),
          AgentPlatformPanel(
            agentCount: agentCount,
            runningCount: runningCount,
          ),
          const SizedBox(height: 24),
          Text('Tasks: $taskCount'),
          const SizedBox(height: 8),
          Text('Workspace: $activeMode'),
        ],
      ),
    );
  }
}
