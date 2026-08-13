import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/bible/domain/canon_conflict.dart';

void main() {
  test('CanonConflict preserves severity and resolution state', () {
    const conflict = CanonConflict(
      id: 'conflict-1',
      projectId: 'project-1',
      ruleId: 'rule-1',
      targetId: 'scene-18',
      message: 'Purple visual effect conflicts with Void Black.',
      severity: CanonConflictSeverity.error,
    );

    expect(conflict.severity, CanonConflictSeverity.error);
    expect(conflict.resolved, isFalse);
    expect(conflict.resolutionNote, isEmpty);
  });
}
