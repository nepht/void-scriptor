import '../graph/knowledge_graph.dart';

/// Universe consistency validator (Step 38.7–38.9).
class UniverseValidator {
  List<String> validate(KnowledgeGraph graph) {
    final violations = <String>[];

    // duplicate title within type
    final seen = <String, String>{};
    for (final entry in graph.entities) {
      final key = '${entry.type.name}:${entry.title.toLowerCase()}';
      if (seen.containsKey(key)) {
        violations.add(
          'Duplicate ${entry.type.name} title "${entry.title}" '
          '(${seen[key]} vs ${entry.id})',
        );
      } else {
        seen[key] = entry.id;
      }
    }

    // dangling relations
    for (final relation in graph.relations) {
      if (graph.entity(relation.sourceId) == null) {
        violations.add('Relation source "${relation.sourceId}" does not exist');
      }
      if (graph.entity(relation.targetId) == null) {
        violations.add('Relation target "${relation.targetId}" does not exist');
      }
    }

    return violations;
  }
}
