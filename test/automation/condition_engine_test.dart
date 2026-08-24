import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/automation_condition.dart';

/// Sprint 104 / 104.6 — deterministic, bounded condition evaluation.
/// There is deliberately NO way to inject code: the operator set is a
/// closed enum and evaluation is a pure function over typed facts.
void main() {
  const engine = AutomationConditionEngine();

  AutomationCondition c(String f, ConditionOperator op, Object v) =>
      AutomationCondition(field: f, op: op, value: v);

  test('typed operators evaluate as specified', () {
    const context = AutomationContext(
      facts: {
        'job.status': 'completed',
        'attempt': 3,
        'ratio': 0.75,
        'tags': ['a', 'b'],
      },
    );
    expect(
      engine.allMatch([
        c('job.status', ConditionOperator.equals, 'completed'),
      ], context),
      isTrue,
    );
    expect(
      engine.allMatch([
        c('job.status', ConditionOperator.notEquals, 'failed'),
      ], context),
      isTrue,
    );
    expect(
      engine.allMatch([
        c('attempt', ConditionOperator.greaterThan, 2),
      ], context),
      isTrue,
    );
    expect(
      engine.allMatch([c('ratio', ConditionOperator.lessThan, 0.8)], context),
      isTrue,
    );
    expect(
      engine.allMatch([c('tags', ConditionOperator.contains, 'b')], context),
      isTrue,
    );
    expect(
      engine.allMatch([
        c('attempt', ConditionOperator.inSet, [1, 3]),
      ], context),
      isTrue,
    );
  });

  test('AND semantics across multiple conditions', () {
    const context = AutomationContext(facts: {'attempt': 3, 'ok': true});
    expect(
      engine.allMatch([
        c('attempt', ConditionOperator.greaterThan, 1),
        c('ok', ConditionOperator.equals, true),
      ], context),
      isTrue,
    );
    expect(
      engine.allMatch([
        c('attempt', ConditionOperator.greaterThan, 1),
        c('ok', ConditionOperator.equals, false),
      ], context),
      isFalse,
    );
  });

  test('unknown or missing fields FAIL CLOSED', () {
    const context = AutomationContext(facts: {'a': 1});
    expect(
      engine.allMatch([c('ghost', ConditionOperator.equals, 1)], context),
      isFalse,
    );
    // Even negations cannot resurrect a missing fact.
    expect(
      engine.allMatch([c('ghost', ConditionOperator.notEquals, 1)], context),
      isFalse,
    );
  });

  test('deterministic: identical inputs, identical verdict', () {
    const context = AutomationContext(facts: {'attempt': 3});
    final conditions = [c('attempt', ConditionOperator.greaterThan, 2)];
    expect(
      engine.allMatch(conditions, context),
      engine.allMatch(conditions, context),
    );
  });
}
