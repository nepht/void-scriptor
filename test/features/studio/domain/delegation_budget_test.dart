import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/studio/domain/delegation_budget.dart';

void main() {
  test('decomposes a task without exceeding recursion depth', () {
    const engine = DelegationEngine(maxDepth: 1);
    expect(engine.decompose('episode', depth: 0), [
      'episode.part1',
      'episode.part2',
    ]);
    expect(engine.decompose('episode', depth: 2), isEmpty);
  });

  test('tracks agent status, capacity, and queue ordering', () {
    final queue = StudioTaskQueue(capacity: 1);
    expect(queue.enqueue(const StudioTask(id: 'low', priority: 1)), isTrue);
    expect(queue.enqueue(const StudioTask(id: 'high', priority: 3)), isFalse);
    expect(queue.next()?.id, 'low');
    expect(queue.status, AgentStatus.idle);
  });

  test('budget gate enforces compute and project hard limits', () {
    const budget = StudioBudget(computeUnits: 10, projectUnits: 100);
    expect(budget.gate(compute: 10, project: 100), isTrue);
    expect(budget.gate(compute: 11, project: 100), isFalse);
    expect(budget.gate(compute: 10, project: 101), isFalse);
  });
}
