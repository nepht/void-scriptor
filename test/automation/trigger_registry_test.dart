import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/trigger_registry.dart';
import 'package:void_scriptor/automation/workflow_trigger.dart';

/// Sprint 104 / 104.4 — one canonical trigger-type registry.
WorkflowTrigger triggerOf(WorkflowTriggerType type) => WorkflowTrigger(
  triggerId: 't-${type.name}',
  type: type,
  configuration: const {},
  createdAt: DateTime.utc(2026, 8, 25),
  updatedAt: DateTime.utc(2026, 8, 25),
);

void main() {
  test('canonical registry knows exactly the six initial types', () {
    const registry = WorkflowTriggerRegistry.canonical();
    expect(registry.registeredTypes.length, 6);
    for (final type in WorkflowTriggerType.values) {
      expect(registry.isRegistered(type), isTrue, reason: type.name);
    }
  });

  test('empty registry fails closed on unregistered types', () {
    const registry = WorkflowTriggerRegistry();
    expect(registry.isRegistered(WorkflowTriggerType.jobEvent), isFalse);
    expect(
      () => registry.assertTypeAllowed(WorkflowTriggerType.jobEvent),
      throwsA(isA<StateError>()),
    );
  });

  test('validateTrigger passes inside canonical registry', () {
    const registry = WorkflowTriggerRegistry.canonical();
    expect(
      registry.validateTrigger(triggerOf(WorkflowTriggerType.assetEvent)),
      isEmpty,
    );
  });
}
