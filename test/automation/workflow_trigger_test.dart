import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/workflow_trigger.dart';

/// Sprint 104 / 104.3 — typed, versioned workflow trigger model.
void main() {
  final now = DateTime.utc(2026, 8, 25);

  test('carries all canonical fields with safe defaults', () {
    final trigger = WorkflowTrigger(
      triggerId: 't-1',
      type: WorkflowTriggerType.schedule,
      configuration: const {'cron': '0 9 * * *', 'timezone': 'Asia/Jakarta'},
      createdAt: now,
      updatedAt: now,
    );
    expect(trigger.enabled, isTrue, reason: 'triggers start enabled');
    expect(trigger.version, 1);
    expect(trigger.policy.maxTriggersPerHour, greaterThan(0));
    expect(trigger.configuration['timezone'], 'Asia/Jakarta');
  });

  test('copyWith never mutates the original; explicit version bump', () {
    final trigger = WorkflowTrigger(
      triggerId: 't-2',
      type: WorkflowTriggerType.projectEvent,
      configuration: const {'event': 'project.opened'},
      createdAt: now,
      updatedAt: now,
    );
    final revised = trigger.copyWith(
      configuration: const {'event': 'project.closed'},
      version: 2,
      updatedAt: now.add(const Duration(hours: 1)),
    );
    expect(trigger.configuration['event'], 'project.opened');
    expect(trigger.version, 1);
    expect(revised.version, 2);
    expect(revised.updatedAt.isAfter(revised.createdAt), isTrue);
  });

  test('all six canonical trigger types exist', () {
    expect(WorkflowTriggerType.values.map((t) => t.name).toSet(), {
      'manual',
      'schedule',
      'projectEvent',
      'assetEvent',
      'jobEvent',
      'pluginEvent',
    });
  });
}
