/// Sprint 104 / 104.3 — typed, versioned workflow trigger model.
library;

enum WorkflowTriggerType {
  manual,
  schedule,
  projectEvent,
  assetEvent,
  jobEvent,
  pluginEvent,
}

/// Rate/burst guardrails evaluated by the automation runtime (104.23 will
/// build on these defaults).
class WorkflowTriggerPolicy {
  const WorkflowTriggerPolicy({
    this.maxTriggersPerHour = 60,
    this.cooldown = Duration.zero,
  });

  final int maxTriggersPerHour;
  final Duration cooldown;
}

class WorkflowTrigger {
  const WorkflowTrigger({
    required this.triggerId,
    required this.type,
    required this.configuration,
    this.enabled = true,
    this.policy = const WorkflowTriggerPolicy(),
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  final String triggerId;
  final WorkflowTriggerType type;

  /// Typed configuration payload (e.g. cron + timezone for schedules,
  /// event name for lifecycle events). Identifiers only — never secrets.
  final Map<String, Object> configuration;
  final bool enabled;
  final WorkflowTriggerPolicy policy;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkflowTrigger copyWith({
    Map<String, Object>? configuration,
    bool? enabled,
    WorkflowTriggerPolicy? policy,
    int? version,
    DateTime? updatedAt,
  }) => WorkflowTrigger(
    triggerId: triggerId,
    type: type,
    configuration: configuration ?? this.configuration,
    enabled: enabled ?? this.enabled,
    policy: policy ?? this.policy,
    version: version ?? this.version,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
