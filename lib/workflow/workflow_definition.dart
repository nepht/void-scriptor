import 'workflow_policies.dart';

/// Sprint 103 / 103.4-103.5 — versioned workflow definition and typed steps.
///
/// Required canonical fields:
///   * definition: workflow_id, name, version, steps, inputs, outputs,
///     policy, created_at, updated_at.
///   * step: step_id, command_type, input_bindings, output_bindings,
///     retry_policy, timeout, failure_policy.

/// A typed value reference between workflow parts.
///
/// Reference grammar (v1):
///   * `in.<input>`      — a declared workflow input.
///   * `step.<id>.<out>` — an output of an earlier step.
///   * `out.<output>`    — a declared workflow output (for output bindings).
class WorkflowBinding {
  const WorkflowBinding(this.name, this.reference);

  /// Local binding name inside the step.
  final String name;

  /// Where the value comes from / goes to (`in.*`, `step.*`, `out.*`).
  final String reference;
}

/// Capabilities a workflow may request; validated against command
/// capabilities by the validation service (deny-by-default downstream).
class WorkflowPolicy {
  const WorkflowPolicy({this.allowedCapabilities = const {}});

  final Set<String> allowedCapabilities;
}

/// One typed execution unit of a workflow.
class WorkflowStep {
  WorkflowStep({
    required this.stepId,
    required this.commandType,
    this.dependsOn = const [],
    this.inputBindings = const [],
    this.outputBindings = const [],
    this.retryPolicy = const WorkflowRetryPolicy(),
    this.timeout = const Duration(minutes: 10),
    this.failurePolicy,
    bool optional = false,
  }) : isOptional = optional;

  final String stepId;
  final String commandType;
  final List<String> dependsOn;
  final List<WorkflowBinding> inputBindings;
  final List<WorkflowBinding> outputBindings;

  /// Bounded retry policy (103.17); auto-retry only when idempotent.
  final WorkflowRetryPolicy retryPolicy;

  /// Per-step wall-clock budget (103.18); prevents unbounded hangs.
  final Duration timeout;

  /// Explicit failure behavior (103.19); null inherits from [isOptional].
  final WorkflowFailurePolicy? failurePolicy;

  /// Optional steps may be skipped under `skipIfOptional`.
  final bool isOptional;

  WorkflowFailurePolicy get effectiveFailurePolicy =>
      failurePolicy ?? WorkflowFailurePolicy.forStep(optional: isOptional);
}

/// A complete, versioned workflow definition.
class WorkflowDefinition {
  WorkflowDefinition({
    required this.workflowId,
    required this.name,
    required this.version,
    required this.steps,
    this.inputs = const [],
    this.outputs = const [],
    required this.policy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String workflowId;
  final String name;
  final int version;
  final List<WorkflowStep> steps;
  final List<String> inputs;
  final List<String> outputs;
  final WorkflowPolicy policy;
  final DateTime createdAt;
  final DateTime updatedAt;
}
