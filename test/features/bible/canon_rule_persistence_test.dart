import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/bible/application/canon_rule_repository.dart';
import 'package:void_scriptor/features/bible/domain/canon_rule.dart';

void main() {
  test('structured canon rules and conditions survive restart', () async {
    final root = await Directory.systemTemp.createTemp('s21-canon-');
    addTearDown(() => root.delete(recursive: true));
    final dbPath = '${root.path}/project.db';
    final service = ProjectDatabaseService();
    await service.create(dbPath);

    final first = await service.open(dbPath);
    final repository = CanonRuleRepository(first);
    await repository.saveRule(
      const CanonRule(
        id: 'rule-1',
        projectId: 'project-1',
        title: 'Void Black uniqueness',
        ruleText: 'Void Black cannot be artificially reproduced.',
        scope: CanonRuleScope.powerSystem,
        scopeTargetId: 'power-void-black',
      ),
    );
    await repository.saveCondition(
      const CanonRuleCondition(
        id: 'condition-1',
        ruleId: 'rule-1',
        validatorType: CanonValidatorType.forbiddenValue,
        targetField: 'creationMethod',
        operator: 'equals',
        expectedValue: 'artificial',
      ),
    );
    await first.close();

    final second = await service.open(dbPath);
    addTearDown(second.close);
    final rules = await CanonRuleRepository(second).listRules('project-1');
    final conditions = await CanonRuleRepository(
      second,
    ).conditionsFor('rule-1');

    expect(second.schemaVersion, 35);
    expect(rules.single.scope, CanonRuleScope.powerSystem);
    expect(rules.single.scopeTargetId, 'power-void-black');
    expect(conditions.single.validatorType, CanonValidatorType.forbiddenValue);
    expect(conditions.single.expectedValue, 'artificial');
  });
}
