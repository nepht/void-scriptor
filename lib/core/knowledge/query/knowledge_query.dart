import '../entity/knowledge_entity.dart';
import '../graph/knowledge_graph.dart';

/// Keyword search over entities and facts (Step 38.10).
class KnowledgeQuery {
  KnowledgeQuery(this.graph);

  final KnowledgeGraph graph;

  List<KnowledgeEntity> search(String query) {
    final lowered = query.toLowerCase();
    return [
      for (final entity in graph.entities)
        if (entity.title.toLowerCase().contains(lowered) ||
            entity.facts.any((f) => f.toLowerCase().contains(lowered)))
          entity,
    ];
  }
}
