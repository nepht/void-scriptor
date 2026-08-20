import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/studio/domain/agent_selection.dart';

void main() {
  test('matches capabilities and scores agents deterministically', () {
    const director = StudioAgentProfile(
      id: 'a1',
      name: 'Director',
      role: 'director',
      personality: 'decisive',
      authority: 0.8,
      capabilities: {'breakdown', 'review'},
    );
    const writer = StudioAgentProfile(
      id: 'a2',
      name: 'Writer',
      role: 'writer',
      personality: 'reflective',
      authority: 0.5,
      capabilities: {'draft'},
    );
    final selector = AgentSelector([director, writer]);
    expect(selector.select('breakdown')?.id, 'a1');
    expect(
      selector.score(director, 'review'),
      greaterThan(selector.score(writer, 'review')),
    );
  });

  test('human override wins over automatic selection', () {
    const a = StudioAgentProfile(
      id: 'a',
      name: 'A',
      role: 'writer',
      personality: 'calm',
      authority: .5,
      capabilities: {'draft'},
    );
    const b = StudioAgentProfile(
      id: 'b',
      name: 'B',
      role: 'reviewer',
      personality: 'strict',
      authority: .7,
      capabilities: {'draft'},
    );
    final selector = AgentSelector([a, b]);
    expect(selector.select('draft', overrideAgentId: 'a')?.id, 'a');
    expect(selector.select('unknown'), isNull);
  });
}
