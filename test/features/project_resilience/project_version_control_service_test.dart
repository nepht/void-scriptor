import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/features/project_resilience/application/project_version_control_service.dart';

void main() {
  test('creates, compares, restores, and prunes project snapshots', () async {
    final root = await Directory.systemTemp.createTemp('s25-versioning-');
    addTearDown(() => root.delete(recursive: true));
    final package = ProjectPackage(projectId: 'p1', root: root);
    final service = ProjectVersionControlService(package);

    final first = await service.createSnapshot(
      label: 'Initial',
      assetType: 'character',
      assetId: 'c1',
      data: {'name': 'Qowner', 'age': 20},
    );
    final second = await service.createSnapshot(
      label: 'Renamed',
      assetType: 'character',
      assetId: 'c1',
      data: {'name': 'Void Scriptor', 'age': 20},
    );

    final diff = await service.compare(first.id, second.id);
    expect(diff.changed['name'], isNotNull);
    expect((await service.listSnapshots()).length, 2);

    Map<String, Object?>? restored;
    await service.restore(second.id, (data) async {
      restored = data;
    });
    expect(restored?['name'], 'Void Scriptor');

    final removed = await service.prune(1);
    expect(removed, 1);
    expect((await service.listSnapshots()).length, 1);
  });
}
