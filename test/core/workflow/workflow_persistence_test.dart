import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart' as db;

/// Sprint 103 / 103.22 — workflow persistence through the canonical
/// project database (schema v57, additive on top of user-owned v55).
void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('vs_wf_persist'));
  tearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('schema migrates to v57 and creates workflow tables', () async {
    final database = db.ProjectDatabase(
      NativeDatabase(File('${dir.path}/project.db')),
    );
    await database.customSelect('SELECT 1').get();
    expect(db.ProjectDatabase.currentSchemaVersion, 58);
    final tables = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
        .get();
    final names = tables.map((r) => r.data['name'] as String).toSet();
    expect(
      names,
      containsAll(['workflow_definitions', 'workflow_run_records']),
    );
    await database.close();
  });

  test('roundtrip persists a workflow definition', () async {
    final database = db.ProjectDatabase(
      NativeDatabase(File('${dir.path}/project.db')),
    );
    await database.customSelect('SELECT 1').get();
    await database
        .into(database.workflowDefinitions)
        .insert(
          db.WorkflowDefinitionsCompanion.insert(
            definitionId: 'd-1',
            name: 'Rename assets',
            version: 1,
            payloadJson: '{"steps":2}',
            createdAt: DateTime.utc(2026, 8, 24),
          ),
        );
    final rows = await database.select(database.workflowDefinitions).get();
    expect(rows.single.definitionId, 'd-1');
    await database.close();
  });
}
