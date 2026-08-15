import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/database_maintenance_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';

void main() {
  late Directory root;
  late File databaseFile;
  late ProjectDatabase db;
  late DatabaseMaintenanceService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-s26-maint-');
    databaseFile = File('${root.path}/project.db');
    await ProjectDatabaseService().create(databaseFile.path);
    db = await ProjectDatabaseService().open(databaseFile.path);
    service = DatabaseMaintenanceService(db);
  });

  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
  });

  test('integrity check reports ok for a healthy database', () async {
    final result = await service.integrityCheck();
    expect(result.healthy, isTrue);
  });

  test('analyze and optimize run without error', () async {
    await service.analyze();
    await service.optimize();
    // Reaching here without throwing is the acceptance.
  });

  test('maintenance operations are listed for the UI', () {
    expect(
      DatabaseMaintenanceService.operations,
      containsAll(['Analyze', 'Optimize', 'Integrity Check', 'Vacuum']),
    );
  });
}
