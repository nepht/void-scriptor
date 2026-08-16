import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/core/enterprise/persistence/studio_repository.dart';

void main() {
  test('saveMember and listMembers roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StudioRepository(database: db);

    await repo.saveMember(
      userId: 'u1',
      studioId: 'st1',
      role: 'member',
      status: 'active',
    );
    final members = await repo.listMembers('st1');
    expect(members, hasLength(1));
    expect(members.first.role, 'member');
  });

  test('appendEvent and listEvents roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = StudioRepository(database: db);

    await repo.appendEvent(
      id: 'e1',
      actor: 'u1',
      action: 'create',
      target: 'shot-1',
    );
    final events = await repo.listEvents('u1');
    expect(events, hasLength(1));
    expect(events.first.action, 'create');
  });

  test('restart persistence keeps members', () async {
    final dir = Directory.systemTemp.createTempSync('vs_studio_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/project.db');

    final db = ProjectDatabase(NativeDatabase(file));
    final repo = StudioRepository(database: db);
    await repo.saveMember(
      userId: 'u1',
      studioId: 'st1',
      role: 'member',
      status: 'active',
    );
    await db.close();

    final db2 = ProjectDatabase(NativeDatabase(file));
    addTearDown(db2.close);
    final repo2 = StudioRepository(database: db2);
    expect((await repo2.listMembers('st1')), hasLength(1));
  });
}
