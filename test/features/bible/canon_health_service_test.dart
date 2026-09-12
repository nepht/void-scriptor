import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/bible/application/canon_health_service.dart';
import 'package:void_scriptor/features/bible/domain/canon_conflict.dart';

void main() {
  test(
    'canon health weights unresolved conflicts without pretending precision',
    () {
      const conflicts = [
        CanonConflict(
          id: 'critical',
          projectId: 'project-1',
          ruleId: 'rule-1',
          targetId: 'byte',
          message: 'Duplicate Byte.',
          severity: CanonConflictSeverity.critical,
        ),
        CanonConflict(
          id: 'warning',
          projectId: 'project-1',
          ruleId: 'rule-2',
          targetId: 'scene-1',
          message: 'Timeline uncertain.',
          severity: CanonConflictSeverity.warning,
        ),
        CanonConflict(
          id: 'resolved',
          projectId: 'project-1',
          ruleId: 'rule-3',
          targetId: 'scene-2',
          message: 'Resolved issue.',
          severity: CanonConflictSeverity.error,
          resolved: true,
        ),
      ];

      final summary = CanonHealthService().summarize(conflicts);

      expect(summary.critical, 1);
      expect(summary.warnings, 1);
      expect(summary.unresolvedWeight, 7);
      expect(summary.healthPercent, 93);
    },
  );

  test('canon health counts unresolved info conflicts instead of hiding them '
      '(vs-hunt-20260913-bible BUG-3)', () {
    const conflicts = [
      CanonConflict(
        id: 'info-open',
        projectId: 'project-1',
        ruleId: 'rule-1',
        targetId: 'scene-1',
        message: 'Loose mention.',
        severity: CanonConflictSeverity.info,
      ),
      CanonConflict(
        id: 'info-resolved',
        projectId: 'project-1',
        ruleId: 'rule-2',
        targetId: 'scene-2',
        message: 'Already handled.',
        severity: CanonConflictSeverity.info,
        resolved: true,
      ),
    ];

    final summary = CanonHealthService().summarize(conflicts);

    // info menambah weight 1 per item yang belum terselesaikan;
    // tanpa field info, kontribusi itu tidak terlihat sama sekali.
    expect(summary.info, 1);
    expect(summary.unresolvedWeight, 1);
    expect(summary.healthPercent, 99);
  });
}
