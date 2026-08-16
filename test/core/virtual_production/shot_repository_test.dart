import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/core/virtual_production/persistence/shot_repository.dart';

void main() {
  test('saveShot and listShots roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = ShotRepository(database: db);

    await repo.saveShot(
      id: 's1',
      name: 'opening',
      startSeconds: 0,
      durationSeconds: 5,
      cameraId: 'c1',
    );
    final shots = await repo.listShots();
    expect(shots, hasLength(1));
    expect(shots.first.name, 'opening');
  });

  test('saveTake and listTakes roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = ShotRepository(database: db);

    await repo.saveTake(
      id: 't1',
      shotId: 's1',
      takeNumber: 1,
      state: 'review',
      notes: 'good',
    );
    final takes = await repo.listTakes('s1');
    expect(takes, hasLength(1));
    expect(takes.first.state, 'review');
  });

  test('restart persistence keeps shots', () async {
    final dir = Directory.systemTemp.createTempSync('vs_shot_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/project.db');

    final db = ProjectDatabase(NativeDatabase(file));
    final repo = ShotRepository(database: db);
    await repo.saveShot(
      id: 's1',
      name: 'opening',
      startSeconds: 0,
      durationSeconds: 5,
      cameraId: 'c1',
    );
    await db.close();

    final db2 = ProjectDatabase(NativeDatabase(file));
    addTearDown(db2.close);
    final repo2 = ShotRepository(database: db2);
    expect((await repo2.listShots()), hasLength(1));
  });
}
