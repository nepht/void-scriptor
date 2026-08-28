import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/agent/presentation/agent_platform_panel.dart';
import 'package:void_scriptor/core/enterprise/presentation/studio_management_panel.dart';
import 'package:void_scriptor/features/studio/presentation/studio_command_center.dart';

void main() {
  testWidgets(
    'command center composes governance, agents, tasks, and workspace',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StudioCommandCenter(
            studioName: 'Void Studio',
            plan: 'Creator',
            usedSeats: 2,
            maxSeats: 5,
            agentCount: 3,
            runningCount: 1,
            taskCount: 2,
            activeMode: 'Production',
          ),
        ),
      );

      expect(find.text('STUDIO COMMAND CENTER'), findsOneWidget);
      expect(find.byType(StudioManagementPanel), findsOneWidget);
      expect(find.byType(AgentPlatformPanel), findsOneWidget);
      expect(find.text('Tasks: 2'), findsOneWidget);
      expect(find.text('Workspace: Production'), findsOneWidget);
    },
  );
}
