import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/knowledge/entity/knowledge_entity.dart';
import 'package:void_scriptor/core/knowledge/entity/entity_relation.dart';
import 'package:void_scriptor/core/knowledge/graph/knowledge_graph.dart';

void main() {
  KnowledgeGraph buildGraph() {
    final graph = KnowledgeGraph();
    graph.addEntity(
      const KnowledgeEntity(id: 'a', type: EntityType.character, title: 'Kael'),
    );
    graph.addEntity(
      const KnowledgeEntity(id: 'b', type: EntityType.character, title: 'Mira'),
    );
    graph.addEntity(
      const KnowledgeEntity(id: 'c', type: EntityType.location, title: 'North'),
    );
    graph.addRelation(
      const EntityRelation(sourceId: 'a', targetId: 'b', kind: 'ally'),
    );
    graph.addRelation(
      const EntityRelation(sourceId: 'a', targetId: 'c', kind: 'bornIn'),
    );
    return graph;
  }

  test('KnowledgeGraph neighbors', () {
    final graph = buildGraph();
    expect(graph.neighbors('a'), hasLength(2));
  });

  test('KnowledgeGraph relationsOf', () {
    final graph = buildGraph();
    expect(graph.relationsOf('a'), hasLength(2));
    expect(graph.relationsOf('b'), hasLength(1));
  });

  test('KnowledgeGraph traverse BFS with maxDepth', () {
    final graph = buildGraph();
    final visited = graph.traverse('a', maxDepth: 1);
    expect(visited, containsAll(['a', 'b', 'c']));
  });
}
