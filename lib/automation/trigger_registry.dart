import 'workflow_trigger.dart';

/// Sprint 104 / 104.4 — THE single canonical registry of trigger types.
/// Nothing may fire a trigger whose type is not registered here.

class WorkflowTriggerRegistry {
  const WorkflowTriggerRegistry({this.registeredTypes = const {}});

  /// The six initial types mandated by Sprint 104 / 104.4.
  const WorkflowTriggerRegistry.canonical()
    : registeredTypes = const {
        WorkflowTriggerType.manual,
        WorkflowTriggerType.schedule,
        WorkflowTriggerType.projectEvent,
        WorkflowTriggerType.assetEvent,
        WorkflowTriggerType.jobEvent,
        WorkflowTriggerType.pluginEvent,
      };

  final Set<WorkflowTriggerType> registeredTypes;

  bool isRegistered(WorkflowTriggerType type) => registeredTypes.contains(type);

  /// Fails closed: an unregistered type must never pass silently.
  void assertTypeAllowed(WorkflowTriggerType type) {
    if (!isRegistered(type)) {
      throw StateError('trigger type not registered: ${type.name}');
    }
  }

  /// Structural validation of a concrete trigger against this registry.
  /// Returns human-readable issues; empty means acceptable.
  List<String> validateTrigger(WorkflowTrigger trigger) {
    final issues = <String>[];
    if (!isRegistered(trigger.type)) {
      issues.add('unregistered trigger type: ${trigger.type.name}');
    }
    if (trigger.triggerId.trim().isEmpty) {
      issues.add('triggerId must not be empty');
    }
    return issues;
  }
}
