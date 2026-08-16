import '../entity/knowledge_entity.dart';
import '../entity/entity_relation.dart';
import '../graph/knowledge_graph.dart';

/// Built-in demo knowledge graph (Step 38.20).
class DemoKnowledge {
  DemoKnowledge._();

  static final KnowledgeGraph graph = KnowledgeGraph()
    ..addEntity(
      const KnowledgeEntity(
        id: 'kael',
        type: EntityType.character,
        title: 'Kael the Void Warden',
        facts: ['born in the north', 'wields a void blade'],
      ),
    )
    ..addEntity(
      const KnowledgeEntity(
        id: 'mira',
        type: EntityType.character,
        title: 'Mira',
        facts: ['ally of Kael'],
      ),
    )
    ..addEntity(
      const KnowledgeEntity(
        id: 'north',
        type: EntityType.location,
        title: 'The Frozen North',
        facts: ['pole territory', 'volcanic border'],
      ),
    )
    ..addRelation(
      const EntityRelation(sourceId: 'kael', targetId: 'mira', kind: 'ally'),
    )
    ..addRelation(
      const EntityRelation(sourceId: 'kael', targetId: 'north', kind: 'bornIn'),
    );
}
