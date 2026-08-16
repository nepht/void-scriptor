import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/core/audio_engine/persistence/automation_repository.dart';

void main() {
  test('saveCurvePoint and listCurvePoints roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = AutomationRepository(database: db);

    await repo.saveCurvePoint(
      id: 'c1',
      clipId: 'clip1',
      parameter: 'gain',
      interpolation: 'linear',
      timeSeconds: 0.5,
      value: -6.0,
    );
    final points = await repo.listCurvePoints('clip1');
    expect(points, hasLength(1));
    expect(points.first.parameter, 'gain');
    expect(points.first.value, -6.0);
  });

  test('restart persistence keeps curve points', () async {
    final dir = Directory.systemTemp.createTempSync('vs_aut_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/project.db');

    final db = ProjectDatabase(NativeDatabase(file));
    final repo = AutomationRepository(database: db);
    await repo.saveCurvePoint(
      id: 'c1',
      clipId: 'clip1',
      parameter: 'gain',
      interpolation: 'linear',
      timeSeconds: 0.5,
      value: -6.0,
    );
    await db.close();

    final db2 = ProjectDatabase(NativeDatabase(file));
    addTearDown(db2.close);
    final repo2 = AutomationRepository(database: db2);
    expect((await repo2.listCurvePoints('clip1')), hasLength(1));
  });
}
