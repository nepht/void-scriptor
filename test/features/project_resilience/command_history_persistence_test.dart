import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';

void main() {
  test('project database persists project-scoped command history', () async {
    final root = await Directory.systemTemp.createTemp('s25-history-');
    addTearDown(() => root.delete(recursive: true));
    final path = '${root.path}/project.db';
    final service = ProjectDatabaseService();
    await service.create(path);
    final first = await service.open(path);

    expect(first.schemaVersion, ProjectDatabase.currentSchemaVersion);
    await first
        .into(first.commandHistoryEntries)
        .insert(
          CommandHistoryEntriesCompanion.insert(
            id: 'command-1',
            projectId: 'project-1',
            commandType: 'asset.rename',
            label: 'Rename Qowner',
            payload: jsonEncode({
              'assetId': 'asset-1',
              'name': 'Void Scriptor',
            }),
            undoPayload: Value(jsonEncode({'name': 'Qowner'})),
            sequence: const Value(1),
          ),
        );
    await first.close();

    final second = await service.open(path);
    addTearDown(second.close);
    final rows = await second.select(second.commandHistoryEntries).get();

    expect(rows, hasLength(1));
    expect(rows.single.projectId, 'project-1');
    expect(rows.single.commandType, 'asset.rename');
    expect(rows.single.status, 'applied');
    expect(rows.single.sequence, 1);
  });
}
