import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/agent/presentation/agent_platform_panel.dart';
import 'package:void_scriptor/core/agent/presentation/agent_list.dart';
import 'package:void_scriptor/core/agent/presentation/agent_run_view.dart';

void main() {
  testWidgets('AgentPlatformPanel shows agent count and status', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AgentPlatformPanel(agentCount: 3, runningCount: 1),
        ),
      ),
    );
    expect(find.text('AI Agents'), findsOneWidget);
    expect(find.textContaining('3'), findsWidgets);
    expect(find.textContaining('1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AgentList shows agents', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AgentList(agents: ['Researcher', 'Writer', 'Editor']),
        ),
      ),
    );
    expect(find.text('Researcher'), findsOneWidget);
    expect(find.text('Writer'), findsOneWidget);
    expect(find.text('Editor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AgentRunView shows result', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AgentRunView(
            agentName: 'Researcher',
            state: 'done',
            output: 'found it',
          ),
        ),
      ),
    );
    expect(find.text('Researcher'), findsOneWidget);
    expect(find.text('State: done'), findsOneWidget);
    expect(find.text('Output: found it'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
