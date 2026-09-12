import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/bible/application/canon_validator.dart';
import 'package:void_scriptor/features/bible/domain/canon_rule.dart';

void main() {
  test('forbiddenValue emits a conflict when target value matches', () {
    const rule = CanonRule(
      id: 'rule-purple',
      projectId: 'project-1',
      title: 'No purple Void Black',
      ruleText: 'Void Black cannot contain purple.',
    );
    const condition = CanonRuleCondition(
      id: 'condition-purple',
      ruleId: 'rule-purple',
      validatorType: CanonValidatorType.forbiddenValue,
      targetField: 'visualPalette',
      operator: 'contains',
      expectedValue: 'purple',
    );

    final conflicts = CanonValidator().validate(
      rule: rule,
      condition: condition,
      targetId: 'scene-18',
      values: const {'visualPalette': 'black, purple aura'},
    );

    expect(conflicts.single.message, contains('purple'));
  });

  test('uniqueness emits a conflict when count exceeds one', () {
    const rule = CanonRule(
      id: 'rule-byte',
      projectId: 'project-1',
      title: 'Byte is unique',
      ruleText: 'Only one Byte may exist.',
    );
    const condition = CanonRuleCondition(
      id: 'condition-byte',
      ruleId: 'rule-byte',
      validatorType: CanonValidatorType.uniqueness,
      targetField: 'name',
      operator: 'equals',
      expectedValue: 'Byte',
    );

    final conflicts = CanonValidator().validate(
      rule: rule,
      condition: condition,
      targetId: 'project-1',
      values: const {'count': 2},
    );

    expect(conflicts.single.severity.name, 'critical');
  });

  test('uniqueness message names the duplicated value and count, '
      'never a null expected value', () {
    // vs-hunt-20260913-bible BUG-2: uniqueness conditions carry no
    // expectedValue, so the old shared message rendered
    // `value "null" conflicts with the canon rule`.
    const rule = CanonRule(
      id: 'rule-byte',
      projectId: 'project-1',
      title: 'Byte is unique',
      ruleText: 'Only one Byte may exist.',
    );
    const condition = CanonRuleCondition(
      id: 'condition-byte',
      ruleId: 'rule-byte',
      validatorType: CanonValidatorType.uniqueness,
      targetField: 'name',
      operator: 'equals',
    );

    final conflicts = CanonValidator().validate(
      rule: rule,
      condition: condition,
      targetId: 'char-1',
      values: const {'count': 2, 'name': 'Byte'},
    );

    final message = conflicts.single.message;
    expect(message, isNot(contains('value "null"')));
    expect(message, contains('"Byte"'));
    expect(message, contains('2'));
    expect(message, contains(rule.title));
  });

  test(
    'uniqueness message with missing target field never renders null text',
    () {
      const rule = CanonRule(
        id: 'rule-ghost',
        projectId: 'project-1',
        title: 'Ghost is unique',
        ruleText: 'Only one Ghost may exist.',
      );
      const condition = CanonRuleCondition(
        id: 'condition-ghost',
        ruleId: 'rule-ghost',
        validatorType: CanonValidatorType.uniqueness,
      );

      final conflicts = CanonValidator().validate(
        rule: rule,
        condition: condition,
        targetId: 'project-1',
        values: const {'count': 3},
      );

      final message = conflicts.single.message;
      expect(message, isNot(contains('null')));
      expect(message, contains(rule.title));
    },
  );
}
