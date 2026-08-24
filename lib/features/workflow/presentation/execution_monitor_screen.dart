import 'package:flutter/material.dart';

/// Sprint 103 / 103.26 — Execution Monitor UI.
///
/// Pure projection of a snapshot; no timers, no polling, no engine logic.

class ExecutionMonitorScreen extends StatelessWidget {
  const ExecutionMonitorScreen({required this.snapshot, super.key});

  final WorkflowMonitorSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Execution Monitor')),
      body: snapshot.executions.isEmpty
          ? const Center(child: Text('No executions'))
          : ListView.builder(
              itemCount: snapshot.executions.length,
              itemBuilder: (context, index) {
                final e = snapshot.executions[index];
                final progress = e.totalSteps == 0
                    ? 0.0
                    : e.completedSteps / e.totalSteps;
                return ListTile(
                  key: ValueKey('exec-${e.executionId}'),
                  leading: Icon(_iconFor(e.state)),
                  title: Text(e.executionId),
                  subtitle: LinearProgressIndicator(value: progress),
                  trailing: Text('${e.completedSteps}/${e.totalSteps}'),
                );
              },
            ),
    );
  }

  IconData _iconFor(String state) => switch (state) {
    'succeeded' || 'completed' => Icons.check_circle,
    'failed' => Icons.error,
    'cancelled' || 'cancelling' => Icons.cancel,
    'paused' => Icons.pause_circle,
    _ => Icons.timelapse,
  };
}

/// One row in the monitor.
class WorkflowMonitorEntry {
  const WorkflowMonitorEntry({
    required this.executionId,
    required this.state,
    required this.completedSteps,
    required this.totalSteps,
  });

  final String executionId;
  final String state;
  final int completedSteps;
  final int totalSteps;
}

/// Immutable view-model for the whole screen.
class WorkflowMonitorSnapshot {
  const WorkflowMonitorSnapshot({required this.executions});

  final List<WorkflowMonitorEntry> executions;
}
