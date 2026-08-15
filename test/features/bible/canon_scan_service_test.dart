import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/bible/application/canon_scan_service.dart';
import 'package:void_scriptor/features/bible/domain/canon_rule.dart';

void main() {
  test(
    'scan evaluates enabled rules against entity values and yields conflicts',
    () {
      const rules = [
        CanonRule(
          id: 'r1',
          projectId: 'p1',
          title: 'No purple eyes',
          ruleText: 'Voidlings must not have purple eyes',
          severity: CanonRuleSeverity.hard,
        ),
        CanonRule(
          id: 'r2',
          projectId: 'p1',
          title: 'Unique true name',
          ruleText: 'True names are unique',
          severity: CanonRuleSeverity.hard,
        ),
      ];
      const conditions = [
        CanonRuleCondition(
          id: 'c1',
          ruleId: 'r1',
          validatorType: CanonValidatorType.forbiddenValue,
          targetField: 'eyeColor',
          operator: 'equals',
          expectedValue: 'purple',
        ),
        CanonRuleCondition(
          id: 'c2',
          ruleId: 'r2',
          validatorType: CanonValidatorType.uniqueness,
          targetField: 'trueName',
        ),
      ];
      final entities = <String, Map<String, Object?>>{
        'char-1': {'eyeColor': 'purple', 'trueName': 'Vash'},
        'char-2': {'eyeColor': 'green', 'trueName': 'Vash'},
      };
      final service = CanonScanService();

      final report = service.scan(
        rules: rules,
        conditions: conditions,
        entities: entities,
      );

      expect(report.conflicts, isNotEmpty);
      // r1 fires only for char-1 (purple eyes).
      expect(
        report.conflicts.any((c) => c.ruleId == 'r1' && c.targetId == 'char-1'),
        isTrue,
      );
      expect(
        report.conflicts.any((c) => c.ruleId == 'r1' && c.targetId == 'char-2'),
        isFalse,
      );
      // r2 uniqueness fires because two entities share trueName 'Vash'.
      expect(
        report.conflicts.where((c) => c.ruleId == 'r2').length,
        greaterThan(0),
      );
    },
  );

  test('scan respects canon exceptions (21.35)', () {
    const rule = CanonRule(
      id: 'r1',
      projectId: 'p1',
      title: 'No purple eyes',
      ruleText: 'Voidlings must not have purple eyes',
    );
    const condition = CanonRuleCondition(
      id: 'c1',
      ruleId: 'r1',
      validatorType: CanonValidatorType.forbiddenValue,
      targetField: 'eyeColor',
      operator: 'equals',
      expectedValue: 'purple',
    );
    final entities = <String, Map<String, Object?>>{
      'char-1': {'eyeColor': 'purple'},
    };
    final service = CanonScanService();

    final withException = service.scan(
      rules: [rule],
      conditions: [condition],
      entities: entities,
      exceptions: {'char-1'},
    );
    expect(withException.conflicts, isEmpty);

    final withoutException = service.scan(
      rules: [rule],
      conditions: [condition],
      entities: entities,
    );
    expect(withoutException.conflicts, isNotEmpty);
  });

  test('scan skips disabled rules', () {
    const rule = CanonRule(
      id: 'r1',
      projectId: 'p1',
      title: 'No purple eyes',
      ruleText: 'Voidlings must not have purple eyes',
      enabled: false,
    );
    const condition = CanonRuleCondition(
      id: 'c1',
      ruleId: 'r1',
      validatorType: CanonValidatorType.forbiddenValue,
      targetField: 'eyeColor',
      operator: 'equals',
      expectedValue: 'purple',
    );
    final service = CanonScanService();
    final report = service.scan(
      rules: [rule],
      conditions: [condition],
      entities: {
        'char-1': {'eyeColor': 'purple'},
      },
    );
    expect(report.conflicts, isEmpty);
  });
}
