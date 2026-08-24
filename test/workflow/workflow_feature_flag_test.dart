import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/workflow/workflow_feature_flag.dart';

/// Sprint 103 / 103.2-103.3 — workflow feature flag behind a safe default.
///
/// Contract (sprint_103.json): default_for_stable = OFF,
/// runtime_override_audited = true.
void main() {
  group('WorkflowFeatureFlag', () {
    test('defaults to OFF for stable builds', () {
      expect(WorkflowFeatureFlag().enabled, isFalse);
      expect(WorkflowFeatureFlag.enabledByDefault, isFalse);
    });

    test('runtime override can enable it', () {
      final flag = WorkflowFeatureFlag();
      flag.setEnabled(true, reason: 'alpha validation wave 1');
      expect(flag.enabled, isTrue);
    });

    test('every runtime override emits an audit event', () {
      final events = <WorkflowAuditEvent>[];
      final flag = WorkflowFeatureFlag(
        auditSink: WorkflowAuditSink(onEvent: events.add),
      );
      flag.setEnabled(true, reason: 'r1');
      flag.setEnabled(false, reason: 'r2');

      expect(events.length, 2);
      expect(events[0].action, 'workflow_flag_enabled');
      expect(events[0].reason, 'r1');
      expect(events[1].action, 'workflow_flag_disabled');
      expect(events[1].reason, 'r2');
    });

    test('a failing audit sink never breaks the override', () {
      final flag = WorkflowFeatureFlag(
        auditSink: WorkflowAuditSink(
          onEvent: (_) => throw StateError('sink down'),
        ),
      );
      flag.setEnabled(true, reason: 'must still apply');
      expect(flag.enabled, isTrue);
    });
  });
}
