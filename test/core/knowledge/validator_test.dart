import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/knowledge/entity/knowledge_entity.dart';
import 'package:void_scriptor/core/knowledge/entity/entity_relation.dart';
import 'package:void_scriptor/core/knowledge/graph/knowledge_graph.dart';
import 'package:void_scriptor/core/knowledge/validation/universe_validator.dart';

void main() {
  test('UniverseValidator flags duplicate title within type', () {
    final graph = KnowledgeGraph();
    graph.addEntity(
      const KnowledgeEntity(id: 'a', type: EntityType.character, title: 'Kael'),
    );
    graph.addEntity(
      const KnowledgeEntity(id: 'b', type: EntityType.character, title: 'Kael'),
    );

    final violations = UniverseValidator().validate(graph);
    expect(violations, hasLength(1));
    expect(violations.first, contains('Kael'));
  });

  test('UniverseValidator passes unique titles', () {
    final graph = KnowledgeGraph();
    graph.addEntity(
      const KnowledgeEntity(id: 'a', type: EntityType.character, title: 'Kael'),
    );
    graph.addEntity(
      const KnowledgeEntity(id: 'b', type: EntityType.character, title: 'Mira'),
    );

    expect(UniverseValidator().validate(graph), isEmpty);
  });

  test('UniverseValidator flags dangling relation', () {
    final graph = KnowledgeGraph();
    graph.addEntity(
      const KnowledgeEntity(id: 'a', type: EntityType.character, title: 'Kael'),
    );
    graph.addRelation(
      const EntityRelation(sourceId: 'a', targetId: 'missing', kind: 'ally'),
    );

    final violations = UniverseValidator().validate(graph);
    expect(violations, hasLength(1));
    expect(violations.first, contains('missing'));
  });
}
