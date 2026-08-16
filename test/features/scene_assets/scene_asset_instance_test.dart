import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/scene_assets/application/scene_asset_instance_repository.dart';
import 'package:void_scriptor/features/scene_assets/domain/scene_asset_instance.dart';

void main() {
  test(
    'scene instances preserve state, hierarchy, transform, properties and inherited snapshot',
    () async {
      final root = await Directory.systemTemp.createTemp('s22-instance-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      final dbPath = (await paths.database('p1')).path;
      final service = ProjectDatabaseService();
      await service.create(dbPath);
      final first = await service.open(dbPath);
      final repo = SceneAssetInstanceRepository(first);
      await repo.saveInstance(
        const SceneAssetInstanceModel(
          id: 'cup-1',
          sceneId: 'scene-1',
          assetId: 'cup',
          assetType: SceneAssetType.prop,
          stateId: 'half',
          parentInstanceId: 'qowner-1',
          contextPriority: SceneContextPriority.optional,
          notes: 'Right hand',
        ),
      );
      await repo.saveTransform(
        const SceneInstanceTransformModel(
          instanceId: 'cup-1',
          positionX: 1,
          positionY: 2,
          positionZ: 3,
        ),
      );
      await repo.setProperty(
        instanceId: 'cup-1',
        key: 'cupFill',
        value: 'empty',
      );
      await repo.setProperty(
        instanceId: 'cup-1',
        key: 'location',
        value: 'chair',
      );
      final snapshot = await repo.captureSnapshot(
        sceneId: 'scene-1',
        instanceId: 'cup-1',
        createdAt: DateTime.utc(2026, 8, 14),
      );
      await repo.inheritSnapshot(
        snapshotId: snapshot.id,
        targetSceneId: 'scene-2',
        newInstanceId: 'cup-2',
      );
      await first.close();
      final second = await service.open(dbPath);
      addTearDown(second.close);
      final restored = SceneAssetInstanceRepository(second);
      expect(second.schemaVersion, 42);
      final inherited = await restored.getInstance('cup-2');
      expect(inherited?.assetId, 'cup');
      expect(inherited?.stateId, 'half');
      expect(inherited?.parentInstanceId, isNull);
      expect((await restored.propertiesFor('cup-2'))['cupFill'], 'empty');
      expect((await restored.propertiesFor('cup-2'))['location'], 'chair');
      expect((await restored.getTransform('cup-2'))?.positionZ, 3);
      expect(
        (await restored.snapshotsForScene('scene-1')).single.snapshotData,
        contains('empty'),
      );
    },
  );
  test('continuity validator reports changed state without transition', () {
    final warnings = SceneContinuityValidator().compare(
      previous: {'cupFill': 'empty', 'location': 'chair'},
      current: {'cupFill': 'full', 'location': 'chair'},
      transitions: const {},
    );
    expect(warnings.single, contains('cupFill changed: empty → full'));
    expect(
      SceneContinuityValidator().compare(
        previous: {'damage': '40'},
        current: {'damage': '0'},
        transitions: {'damage'},
      ),
      isEmpty,
    );
  });
}
