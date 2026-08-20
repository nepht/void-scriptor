import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/studio/domain/production_pipeline.dart';

void main() {
  test('director creates tasks with dependencies and blocked state', () {
    final director = ProductionDirector();
    final breakdown = director.breakdown('Create episode');
    final first = breakdown.addTask('Write', mode: DelegationMode.human);
    final second = breakdown.addTask('Review', dependsOn: first.id);
    expect(breakdown.isBlocked(second.id), isTrue);
    breakdown.complete(first.id);
    expect(breakdown.isBlocked(second.id), isFalse);
  });

  test('delegation modes and recursion limit are explicit', () {
    final director = ProductionDirector(maxDelegationDepth: 1);
    expect(director.delegate('task', mode: DelegationMode.agent), isTrue);
    expect(
      director.delegate('nested', mode: DelegationMode.agent, depth: 2),
      isFalse,
    );
  });
}
