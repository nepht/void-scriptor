// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scene_asset_instance_repository.dart';

// ignore_for_file: type=lint
mixin _$SceneAssetInstanceRepositoryMixin on DatabaseAccessor<ProjectDatabase> {
  $SceneAssetInstancesTable get sceneAssetInstances =>
      attachedDatabase.sceneAssetInstances;
  $SceneInstanceTransformsTable get sceneInstanceTransforms =>
      attachedDatabase.sceneInstanceTransforms;
  $SceneInstancePropertiesTable get sceneInstanceProperties =>
      attachedDatabase.sceneInstanceProperties;
  $SceneContinuitySnapshotsTable get sceneContinuitySnapshots =>
      attachedDatabase.sceneContinuitySnapshots;
  SceneAssetInstanceRepositoryManager get managers =>
      SceneAssetInstanceRepositoryManager(this);
}

class SceneAssetInstanceRepositoryManager {
  final _$SceneAssetInstanceRepositoryMixin _db;
  SceneAssetInstanceRepositoryManager(this._db);
  $$SceneAssetInstancesTableTableManager get sceneAssetInstances =>
      $$SceneAssetInstancesTableTableManager(
        _db.attachedDatabase,
        _db.sceneAssetInstances,
      );
  $$SceneInstanceTransformsTableTableManager get sceneInstanceTransforms =>
      $$SceneInstanceTransformsTableTableManager(
        _db.attachedDatabase,
        _db.sceneInstanceTransforms,
      );
  $$SceneInstancePropertiesTableTableManager get sceneInstanceProperties =>
      $$SceneInstancePropertiesTableTableManager(
        _db.attachedDatabase,
        _db.sceneInstanceProperties,
      );
  $$SceneContinuitySnapshotsTableTableManager get sceneContinuitySnapshots =>
      $$SceneContinuitySnapshotsTableTableManager(
        _db.attachedDatabase,
        _db.sceneContinuitySnapshots,
      );
}
