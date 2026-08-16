import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/knowledge/entity/knowledge_entity.dart';
import 'package:void_scriptor/core/knowledge/entity/entity_relation.dart';
import 'package:void_scriptor/core/knowledge/graph/knowledge_graph.dart';
import 'package:void_scriptor/core/knowledge/query/knowledge_query.dart';
import 'package:void_scriptor/core/knowledge/ai/universe_ai.dart';

void main() {
  KnowledgeGraph buildGraph() {
    final graph = KnowledgeGraph();
    graph.addEntity(
      const KnowledgeEntity(
        id: 'a',
        type: EntityType.character,
        title: 'Kael the Void Warden',
        facts: ['born in the north', 'wields a void blade'],
      ),
    );
    graph.addEntity(
      const KnowledgeEntity(
        id: 'b',
        type: EntityType.character,
        title: 'Mira',
        facts: ['ally of Kael'],
      ),
    );
    graph.addRelation(
      const EntityRelation(sourceId: 'a', targetId: 'b', kind: 'ally'),
    );
    return graph;
  }

  test('KnowledgeQuery searches entities and facts', () {
    final graph = buildGraph();
    final results = KnowledgeQuery(graph).search('void');
    expect(results, hasLength(1));
    expect(results.first.id, 'a');
  });

  test('KnowledgeQuery searches by title', () {
    final graph = buildGraph();
    final results = KnowledgeQuery(graph).search('mira');
    expect(results, hasLength(1));
    expect(results.first.id, 'b');
  });

  test('UniverseAi suggests related entities', () {
    final graph = buildGraph();
    final ai = UniverseAi(graph);
    final suggestions = ai.suggest('a');
    expect(suggestions, contains('b'));
  });
}
