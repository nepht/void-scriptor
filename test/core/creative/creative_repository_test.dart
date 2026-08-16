import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/core/creative/persistence/creative_repository.dart';

void main() {
  test('saveBrief and listBriefs roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = CreativeRepository(database: db);

    await repo.saveBrief(
      id: 'b1',
      title: 'Void Warden',
      genre: 'fantasy',
      tone: 'dark',
      goals: ['publish'],
    );
    final briefs = await repo.listBriefs();
    expect(briefs, hasLength(1));
    expect(briefs.first.title, 'Void Warden');
    expect(jsonDecode(briefs.first.goalsJson), ['publish']);
  });

  test('saveIdea and listIdeas roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = CreativeRepository(database: db);

    await repo.saveIdea(
      id: 'i1',
      briefId: 'b1',
      title: 'Warden rises',
      description: 'A warden awakens',
      tags: ['character'],
    );
    final ideas = await repo.listIdeas('b1');
    expect(ideas, hasLength(1));
    expect(jsonDecode(ideas.first.tagsJson), ['character']);
  });

  test('restart persistence keeps briefs', () async {
    final dir = Directory.systemTemp.createTempSync('vs_creative_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/project.db');

    final db = ProjectDatabase(NativeDatabase(file));
    final repo = CreativeRepository(database: db);
    await repo.saveBrief(
      id: 'b1',
      title: 'Void',
      genre: 'x',
      tone: 'y',
      goals: [],
    );
    await db.close();

    final db2 = ProjectDatabase(NativeDatabase(file));
    addTearDown(db2.close);
    final repo2 = CreativeRepository(database: db2);
    expect((await repo2.listBriefs()), hasLength(1));
  });
}
