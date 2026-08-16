import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/core/knowledge/persistence/knowledge_repository.dart';

void main() {
  test('saveEntity and listEntities roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = KnowledgeRepository(database: db);

    await repo.saveEntity(
      id: 'e1',
      type: 'character',
      title: 'Kael',
      facts: ['born in north'],
    );
    final entities = await repo.listEntities();
    expect(entities, hasLength(1));
    expect(entities.first.title, 'Kael');
    expect(jsonDecode(entities.first.factsJson), ['born in north']);
  });

  test('saveRelation and listRelations roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = KnowledgeRepository(database: db);

    await repo.saveRelation(
      id: 'r1',
      sourceId: 'a',
      targetId: 'b',
      kind: 'ally',
    );
    final relations = await repo.listRelations();
    expect(relations, hasLength(1));
    expect(relations.first.kind, 'ally');
  });

  test('restart persistence keeps entities', () async {
    final dir = Directory.systemTemp.createTempSync('vs_know_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/project.db');

    final db = ProjectDatabase(NativeDatabase(file));
    final repo = KnowledgeRepository(database: db);
    await repo.saveEntity(
      id: 'e1',
      type: 'character',
      title: 'Kael',
      facts: [],
    );
    await db.close();

    final db2 = ProjectDatabase(NativeDatabase(file));
    addTearDown(db2.close);
    final repo2 = KnowledgeRepository(database: db2);
    expect((await repo2.listEntities()), hasLength(1));
  });
}
