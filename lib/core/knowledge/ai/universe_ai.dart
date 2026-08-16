import '../entity/knowledge_entity.dart';
import '../graph/knowledge_graph.dart';

/// Assisted retrieval + suggestions over the knowledge graph (Step 38.11–38.12).
class UniverseAi {
  UniverseAi(this.graph);

  final KnowledgeGraph graph;

  List<KnowledgeEntity> retrieve(String query) {
    final lowered = query.toLowerCase();
    final matches = [
      for (final entity in graph.entities)
        if (entity.title.toLowerCase().contains(lowered) ||
            entity.facts.any((f) => f.toLowerCase().contains(lowered)))
          entity,
    ];
    return matches;
  }

  List<String> suggest(String entityId) => graph.neighbors(entityId);
}
