import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/knowledge/entity/knowledge_entity.dart';
import 'package:void_scriptor/core/knowledge/entity/entity_relation.dart';

void main() {
  test('KnowledgeEntity holds identity and facts', () {
    const entity = KnowledgeEntity(
      id: 'e1',
      type: EntityType.character,
      title: 'Kael',
      facts: ['born in the north', 'wields a void blade'],
    );
    expect(entity.title, 'Kael');
    expect(entity.facts, hasLength(2));
  });

  test('EntityRelation holds source and target', () {
    const relation = EntityRelation(
      sourceId: 'e1',
      targetId: 'e2',
      kind: 'ally',
    );
    expect(relation.sourceId, 'e1');
    expect(relation.kind, 'ally');
  });

  test('EntityType enum values', () {
    expect(EntityType.values, hasLength(6));
    expect(EntityType.location.name, 'location');
  });
}
