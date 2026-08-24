import 'workflow_runner.dart';

/// Sprint 103 / 103.27 — audit trail for workflow decisions.
///
/// Canonical event vocabulary; entries carry identifiers ONLY. Free-form
/// detail is deliberately dropped so story content or secrets can never
/// leak into the trail.

enum WorkflowAuditEventKind {
  created,
  validated,
  started,
  paused,
  resumed,
  cancelled,
  failed,
  recovered,
  completed,
}

class WorkflowAuditEntry {
  const WorkflowAuditEntry({
    required this.kind,
    required this.executionId,
    required this.workflowId,
    required this.at,
    this.stepId,
  });

  final WorkflowAuditEventKind kind;
  final String executionId;
  final String workflowId;
  final String? stepId;
  final DateTime at;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'execution_id': executionId,
    'workflow_id': workflowId,
    if (stepId != null) 'step_id': stepId,
    'at': at.toIso8601String(),
  };
}

class WorkflowAuditTrail {
  final List<WorkflowAuditEntry> _entries = [];

  /// Read-only view.
  List<WorkflowAuditEntry> get entries => List.unmodifiable(_entries);

  void record({
    required WorkflowAuditEventKind kind,
    required String executionId,
    required String workflowId,
    String? stepId,

    /// Accepted for call-site readability but NEVER stored.
    Object? detail,
  }) {
    _entries.add(
      WorkflowAuditEntry(
        kind: kind,
        executionId: executionId,
        workflowId: workflowId,
        stepId: stepId,
        at: DateTime.now().toUtc(),
      ),
    );
  }

  /// Maps runner events onto the audit vocabulary; identifier-only.
  static WorkflowAuditEntry forRunnerEvent(WorkflowRunnerEvent event) {
    final kind = switch (event.kind) {
      WorkflowRunnerEventKind.started ||
      WorkflowRunnerEventKind.stepStarted => WorkflowAuditEventKind.started,
      WorkflowRunnerEventKind.paused => WorkflowAuditEventKind.paused,
      WorkflowRunnerEventKind.resumed => WorkflowAuditEventKind.resumed,
      WorkflowRunnerEventKind.cancelled => WorkflowAuditEventKind.cancelled,
      WorkflowRunnerEventKind.stepFailed ||
      WorkflowRunnerEventKind.stepTimedOut => WorkflowAuditEventKind.failed,
      WorkflowRunnerEventKind.completed => WorkflowAuditEventKind.completed,
      WorkflowRunnerEventKind.stepSucceeded ||
      WorkflowRunnerEventKind.stepSkipped => null,
    };
    return WorkflowAuditEntry(
      kind: kind ?? WorkflowAuditEventKind.started,
      executionId: event.executionId,
      workflowId: 'workflow',
      stepId: event.stepId,
      at: DateTime.now().toUtc(),
    );
  }
}
