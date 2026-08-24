/// Sprint 103 — workflow intelligence foundation.
///
/// Domain boundary (103.3): the `package:void_scriptor/workflow/` module owns
/// the workflow-intelligence feature. Dependency rules:
///   * workflow code may depend on `lib/core/` only;
///   * other feature areas must consume workflow through interfaces defined
///     in this module, never by reaching into its internals;
///   * nothing here may import Flutter UI libraries.
library;

/// Where workflow audit lines go. Kept minimal so any sink (file, console,
/// future persistence) can implement it.
class WorkflowAuditSink {
  WorkflowAuditSink({required this.onEvent});

  final void Function(WorkflowAuditEvent event) onEvent;

  void record(WorkflowAuditEvent event) {
    onEvent(event);
  }
}

/// One auditable decision or transition.
class WorkflowAuditEvent {
  const WorkflowAuditEvent({
    required this.action,
    required this.reason,
    required this.at,
  });

  final String action;
  final String reason;
  final DateTime at;
}

/// Feature flag for the whole workflow-intelligence surface.
///
/// Contract from sprint_103.json step 103.2:
///   * default_for_stable = OFF;
///   * runtime_override_audited = true — every change goes through [setEnabled]
///     and emits an audit event; a broken sink never blocks the override.
class WorkflowFeatureFlag {
  WorkflowFeatureFlag({this.auditSink});

  static const bool enabledByDefault = false;

  final WorkflowAuditSink? auditSink;

  bool get enabled => enabledByDefault || _overridden;
  bool _overridden = false;

  /// Audited runtime override.
  void setEnabled(bool value, {required String reason}) {
    _overridden = value;
    try {
      auditSink?.record(
        WorkflowAuditEvent(
          action: value ? 'workflow_flag_enabled' : 'workflow_flag_disabled',
          reason: reason,
          at: DateTime.now().toUtc(),
        ),
      );
    } catch (_) {
      // Audit failures must never break the override itself.
    }
  }
}
