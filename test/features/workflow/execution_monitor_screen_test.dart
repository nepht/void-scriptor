import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workflow/presentation/execution_monitor_screen.dart';

/// Sprint 103 / 103.26 — Execution Monitor widget tests.
WorkflowMonitorSnapshot snap({List<WorkflowMonitorEntry> entries = const []}) =>
    WorkflowMonitorSnapshot(executions: entries);

void main() {
  testWidgets('renders each execution with progress', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExecutionMonitorScreen(
          snapshot: snap(
            entries: [
              const WorkflowMonitorEntry(
                executionId: 'e1',
                state: 'running',
                completedSteps: 1,
                totalSteps: 4,
              ),
              const WorkflowMonitorEntry(
                executionId: 'e2',
                state: 'succeeded',
                completedSteps: 3,
                totalSteps: 3,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('e1'), findsOneWidget);
    expect(find.text('e2'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text('3/3'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
  });

  testWidgets('empty state is explicit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ExecutionMonitorScreen(snapshot: snap())),
    );
    expect(find.text('No executions'), findsOneWidget);
  });
}
