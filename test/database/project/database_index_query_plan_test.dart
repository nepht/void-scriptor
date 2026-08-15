import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/database/project/tables/assets.dart';

void main() {
  late Directory root;
  late File databaseFile;
  late ProjectDatabaseService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-s26-indexplan-');
    databaseFile = File('${root.path}/project.db');
    service = ProjectDatabaseService();
  });

  tearDown(() => root.delete(recursive: true));

  test('project+type query plan uses composite index', () async {
    await service.create(databaseFile.path);
    final db = await service.open(databaseFile.path);
    addTearDown(db.close);

    final now = DateTime.now().toUtc();
    await db.batch((batch) {
      for (var i = 0; i < 50; i++) {
        batch.insert(
          db.assets,
          AssetsCompanion.insert(
            id: 'asset-$i',
            projectId: 'project-1',
            name: 'Asset $i',
            type: 'character',
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    });

    final plan = await db
        .customSelect(
          "EXPLAIN QUERY PLAN SELECT * FROM assets "
          "WHERE project_id = 'project-1' AND type = 'character'",
        )
        .get();

    final planText = plan.map((row) => row.data.values.join(' ')).join('\n');
    expect(
      planText,
      contains('idx_assets_project_type_updated'),
      reason: 'composite index should be used for project+type query',
    );
  });
}
