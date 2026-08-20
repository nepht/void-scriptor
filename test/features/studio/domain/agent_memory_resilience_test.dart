import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/studio/domain/agent_memory_resilience.dart';

void main() {
  test('keeps project memory scoped and supersedes decisions', () {
    final memory = AgentMemory(scope: KnowledgeScope.project);
    memory.remember('project-1', 'Use cold open');
    memory.remember('project-2', 'Use montage');
    expect(memory.forProject('project-1'), ['Use cold open']);
    final decisions = DecisionLedger();
    final first = decisions.add('Use cold open');
    decisions.supersede(first, 'Use montage');
    expect(decisions.active.single.text, 'Use montage');
  });

  test('uses multiple evaluation metrics and supports rollback', () {
    const metrics = EvaluationMetrics(quality: .8, safety: .9, latency: .7);
    expect(metrics.composite, lessThan(1));
    final router = ModelRouter(['local', 'remote']);
    expect(router.select(preferLocal: true), 'local');
    final policy = RollbackPolicy();
    policy.record('v1');
    policy.record('v2');
    expect(policy.rollback(), 'v1');
    expect(const RetryBudget(2).allow(0), isTrue);
    expect(const RetryBudget(2).allow(2), isFalse);
  });
}
