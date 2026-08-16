import '../entity/knowledge_entity.dart';
import '../entity/entity_relation.dart';

/// Knowledge graph with traversal (Step 38.4–38.6).
class KnowledgeGraph {
  final Map<String, KnowledgeEntity> _entities = {};
  final List<EntityRelation> _relations = [];

  void addEntity(KnowledgeEntity entity) => _entities[entity.id] = entity;

  void addRelation(EntityRelation relation) => _relations.add(relation);

  KnowledgeEntity? entity(String id) => _entities[id];

  List<String> neighbors(String id) => [
    for (final relation in _relations)
      if (relation.sourceId == id)
        relation.targetId
      else if (relation.targetId == id)
        relation.sourceId,
  ];

  List<EntityRelation> relationsOf(String id) => [
    for (final relation in _relations)
      if (relation.sourceId == id || relation.targetId == id) relation,
  ];

  Set<String> traverse(String startId, {required int maxDepth}) {
    final visited = <String>{};
    final queue = <String>[startId];
    final depth = <String, int>{startId: 0};
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (visited.contains(current)) continue;
      visited.add(current);
      final currentDepth = depth[current]!;
      if (currentDepth >= maxDepth) continue;
      for (final neighbor in neighbors(current)) {
        if (!visited.contains(neighbor)) {
          queue.add(neighbor);
          depth[neighbor] = currentDepth + 1;
        }
      }
    }
    return visited;
  }

  int get entityCount => _entities.length;
  int get relationCount => _relations.length;

  List<KnowledgeEntity> get entities => List.unmodifiable(_entities.values);
  List<EntityRelation> get relations => List.unmodifiable(_relations);
}
