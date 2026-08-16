import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/core/publishing/persistence/publish_repository.dart';

void main() {
  test('saveRecord and listRecords roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PublishRepository(database: db);

    await repo.saveRecord(
      id: 'r1',
      channel: 'stable',
      version: '1.0.0',
      state: 'published',
      checksum: 'abc',
      changelog: 'release',
    );
    final records = await repo.listRecords('stable');
    expect(records, hasLength(1));
    expect(records.first.version, '1.0.0');
  });

  test('restart persistence keeps records', () async {
    final dir = Directory.systemTemp.createTempSync('vs_pub_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/project.db');

    final db = ProjectDatabase(NativeDatabase(file));
    final repo = PublishRepository(database: db);
    await repo.saveRecord(
      id: 'r1',
      channel: 'stable',
      version: '1.0.0',
      state: 'published',
      checksum: 'abc',
      changelog: 'release',
    );
    await db.close();

    final db2 = ProjectDatabase(NativeDatabase(file));
    addTearDown(db2.close);
    final repo2 = PublishRepository(database: db2);
    expect((await repo2.listRecords('stable')), hasLength(1));
  });
}
