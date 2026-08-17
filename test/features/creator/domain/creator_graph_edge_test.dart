import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/domain/creator_graph_edge.dart';

void main() {
  group('CreatorGraphEdgeType', () {
    test('exposes the six production-relation types', () {
      expect(CreatorGraphEdgeType.values.map((e) => e.name), [
        'follows',
        'collaboratesWith',
        'workedOn',
        'created',
        'owns',
        'contributedTo',
      ]);
    });
  });

  group('CreatorGraphEdge', () {
    test('holds source, target and relation type', () {
      const edge = CreatorGraphEdge(
        id: 'e1',
        sourceCreatorId: 'a',
        targetId: 'b',
        type: CreatorGraphEdgeType.collaboratesWith,
      );
      expect(edge.sourceCreatorId, 'a');
      expect(edge.targetId, 'b');
      expect(edge.type, CreatorGraphEdgeType.collaboratesWith);
    });
  });
}
