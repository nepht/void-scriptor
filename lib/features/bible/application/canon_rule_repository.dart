import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';
import '../../../database/project/tables/canon_rules.dart' as schema;
import '../domain/canon_rule.dart' as domain;
import '../../story/domain/canon_status.dart';

part 'canon_rule_repository.g.dart';

@DriftAccessor(tables: [schema.CanonRules, schema.CanonRuleConditions])
class CanonRuleRepository extends DatabaseAccessor<ProjectDatabase>
    with _$CanonRuleRepositoryMixin {
  CanonRuleRepository(super.database);

  Future<void> saveRule(domain.CanonRule rule) =>
      into(canonRules).insertOnConflictUpdate(
        CanonRulesCompanion.insert(
          id: rule.id,
          projectId: rule.projectId,
          title: rule.title,
          ruleText: rule.ruleText,
          severity: Value(rule.severity.name),
          scope: Value(rule.scope.name),
          scopeTargetId: Value(rule.scopeTargetId),
          canonStatus: Value(rule.status.name),
          enabled: Value(rule.enabled),
        ),
      );

  Future<void> saveCondition(domain.CanonRuleCondition condition) =>
      into(canonRuleConditions).insertOnConflictUpdate(
        CanonRuleConditionsCompanion.insert(
          id: condition.id,
          ruleId: condition.ruleId,
          validatorType: condition.validatorType.name,
          targetField: Value(condition.targetField),
          operator: Value(condition.operator),
          expectedValue: Value(condition.expectedValue),
        ),
      );

  Future<List<domain.CanonRule>> listRules(String projectId) async {
    final rows =
        await (select(canonRules)
              ..where((row) => row.projectId.equals(projectId))
              ..orderBy([(row) => OrderingTerm(expression: row.title)]))
            .get();
    return rows.map(_toRule).toList(growable: false);
  }

  Future<List<domain.CanonRuleCondition>> conditionsFor(String ruleId) async {
    final rows = await (select(
      canonRuleConditions,
    )..where((row) => row.ruleId.equals(ruleId))).get();
    return rows.map(_toCondition).toList(growable: false);
  }

  domain.CanonRule _toRule(CanonRule row) => domain.CanonRule(
    id: row.id,
    projectId: row.projectId,
    title: row.title,
    ruleText: row.ruleText,
    severity: domain.CanonRuleSeverity.values.byName(row.severity),
    scope: domain.CanonRuleScope.values.byName(row.scope),
    scopeTargetId: row.scopeTargetId,
    enabled: row.enabled,
    status: CanonStatus.values.byName(row.canonStatus),
  );

  domain.CanonRuleCondition _toCondition(CanonRuleCondition row) =>
      domain.CanonRuleCondition(
        id: row.id,
        ruleId: row.ruleId,
        validatorType: domain.CanonValidatorType.values.byName(
          row.validatorType,
        ),
        targetField: row.targetField,
        operator: row.operator,
        expectedValue: row.expectedValue,
      );
}
