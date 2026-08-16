import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/core/xr/persistence/xr_repository.dart';

void main() {
  test('saveSession and listSessions roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = XrRepository(database: db);

    await repo.saveSession(id: 's1', state: 'running');
    final sessions = await repo.listSessions();
    expect(sessions, hasLength(1));
    expect(sessions.first.state, 'running');
  });

  test('saveAnchor and listAnchors roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = XrRepository(database: db);

    await repo.saveAnchor(
      id: 'a1',
      sessionId: 's1',
      contentId: 'c1',
      x: 1.0,
      y: 2.0,
      z: 3.0,
    );
    final anchors = await repo.listAnchors('s1');
    expect(anchors, hasLength(1));
    expect(anchors.first.x, 1.0);
  });

  test('restart persistence keeps sessions', () async {
    final dir = Directory.systemTemp.createTempSync('vs_xr_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/project.db');

    final db = ProjectDatabase(NativeDatabase(file));
    final repo = XrRepository(database: db);
    await repo.saveSession(id: 's1', state: 'running');
    await db.close();

    final db2 = ProjectDatabase(NativeDatabase(file));
    addTearDown(db2.close);
    final repo2 = XrRepository(database: db2);
    expect((await repo2.listSessions()), hasLength(1));
  });
}
