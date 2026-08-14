import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/project_resilience/application/command_history_repository.dart';

void main() {
  test('records and filters command history by project', () async {
    final root = await Directory.systemTemp.createTemp('s25-history-repo-');
    addTearDown(() => root.delete(recursive: true));
    final path = '${root.path}/project.db';
    final service = ProjectDatabaseService();
    await service.create(path);
    final database = await service.open(path);
    addTearDown(database.close);
    final repository = CommandHistoryRepository(database);

    await repository.record(
      const CommandHistoryRecordInput(
        id: 'cmd-1',
        projectId: 'p1',
        commandType: 'asset.rename',
        label: 'Rename Qowner',
        payload: {'assetId': 'a1', 'name': 'Void Scriptor'},
        undoPayload: {'name': 'Qowner'},
        sequence: 7,
      ),
    );
    await repository.record(
      const CommandHistoryRecordInput(
        id: 'cmd-2',
        projectId: 'p2',
        commandType: 'asset.rename',
        label: 'Rename Other',
        payload: {'assetId': 'a2', 'name': 'Other'},
        sequence: 1,
      ),
    );

    final rows = await repository.list('p1');
    expect(rows, hasLength(1));
    expect(rows.single.payload['name'], 'Void Scriptor');
    expect(rows.single.undoPayload?['name'], 'Qowner');
    expect(rows.single.status, CommandHistoryStatus.applied);

    await repository.markUndone('cmd-1');
    expect(
      (await repository.list('p1')).single.status,
      CommandHistoryStatus.undone,
    );
  });
}
