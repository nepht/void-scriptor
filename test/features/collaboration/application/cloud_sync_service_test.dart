import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/collaboration/domain/sync_models.dart';
import 'package:void_scriptor/features/collaboration/application/cloud_sync_service.dart';

void main() {
  test(
    'InMemoryCloudSyncService pushes then pulls back the same state',
    () async {
      final service = InMemoryCloudSyncService();
      await service.push(
        projectId: 'p1',
        state: const {
          'character:1': {'name': 'Aria'},
        },
      );
      final pulled = await service.pull('p1');
      expect(pulled, {
        'character:1': {'name': 'Aria'},
      });
    },
  );

  test('sync merges local and remote states', () async {
    final service = InMemoryCloudSyncService();
    // Seed remote with a value local doesn't have.
    await service.push(projectId: 'p1', state: const {'a': '1'});
    final result = await service.sync(
      projectId: 'p1',
      local: const {'a': '1', 'b': '2'},
    );
    expect(result.state, SyncState.synced);
    expect(result.applied, 2);
    expect(result.complete, isTrue);
  });

  test('FolderCloudSyncService roundtrips through disk', () async {
    final dir = Directory.systemTemp.createTempSync('vs_sync_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final service = FolderCloudSyncService(dir);
    await service.push(projectId: 'p1', state: const {'x': 'y'});
    final pulled = await service.pull('p1');
    expect(pulled, {'x': 'y'});
  });
}
