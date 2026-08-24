import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/lifecycle_triggers.dart';

/// Sprint 104 / 104.11 — the five canonical project lifecycle trigger
/// events with identifier-only fact payloads.
void main() {
  test('all five canonical lifecycle events exist', () {
    expect(ProjectLifecycleEvent.values.length, 5);
    expect(
      ProjectLifecycleEvent.values.map((e) => e.name).toSet(),
      containsAll(['projectOpened', 'recoveryCompleted']),
    );
  });

  test('facts carry identifiers only — never story content or secrets', () {
    final facts = lifecycleFacts(
      ProjectLifecycleEvent.projectSaved,
      projectId: 'p-1',
      projectName: 'Void Cube Saga',
    );
    expect(facts['project.event'], 'projectSaved');
    expect(facts['project.id'], 'p-1');
    // Name is metadata, allowed; but nothing secret-shaped may appear.
    expect(facts.keys.any((k) => k.toLowerCase().contains('secret')), isFalse);
  });

  test('health issue exposes severity, not diagnostics payloads', () {
    final facts = lifecycleFacts(
      ProjectLifecycleEvent.healthIssueDetected,
      projectId: 'p-2',
      severity: 'warning',
    );
    expect(facts['severity'], 'warning');
    expect(facts.length <= 4, isTrue, reason: 'minimal by design');
  });
}
