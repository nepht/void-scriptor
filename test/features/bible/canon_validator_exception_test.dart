import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/bible/application/canon_validator.dart';
import 'package:void_scriptor/features/bible/domain/canon_rule.dart';

void main() {
  test('validator skips a target covered by a canon exception', () {
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
      exceptionTargetIds: const {'scene-18'},
    );

    expect(conflicts, isEmpty);
  });
}
