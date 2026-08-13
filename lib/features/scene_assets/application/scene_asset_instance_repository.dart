import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../database/project/project_database.dart';
import '../../../database/project/tables/scene_asset_instances.dart';
import '../domain/scene_asset_instance.dart' as domain;
part 'scene_asset_instance_repository.g.dart';

@DriftAccessor(
  tables: [
    SceneAssetInstances,
    SceneInstanceTransforms,
    SceneInstanceProperties,
    SceneContinuitySnapshots,
  ],
)
class SceneAssetInstanceRepository extends DatabaseAccessor<ProjectDatabase>
    with _$SceneAssetInstanceRepositoryMixin {
  SceneAssetInstanceRepository(super.db);
  Future<void> saveInstance(domain.SceneAssetInstanceModel v) =>
      into(sceneAssetInstances).insertOnConflictUpdate(
        SceneAssetInstancesCompanion.insert(
          id: v.id,
          sceneId: v.sceneId,
          assetId: v.assetId,
          assetType: v.assetType.name,
          stateId: Value(v.stateId),
          parentInstanceId: Value(v.parentInstanceId),
          contextPriority: Value(v.contextPriority.name),
          notes: Value(v.notes),
        ),
      );
  Future<domain.SceneAssetInstanceModel?> getInstance(String id) async {
    final r = await (select(
      sceneAssetInstances,
    )..where((x) => x.id.equals(id))).getSingleOrNull();
    return r == null
        ? null
        : domain.SceneAssetInstanceModel(
            id: r.id,
            sceneId: r.sceneId,
            assetId: r.assetId,
            assetType: domain.SceneAssetType.values.firstWhere(
              (x) => x.name == r.assetType,
            ),
            stateId: r.stateId,
            parentInstanceId: r.parentInstanceId,
            contextPriority: domain.SceneContextPriority.values.firstWhere(
              (x) => x.name == r.contextPriority,
            ),
            notes: r.notes,
          );
  }

  Future<List<domain.SceneAssetInstanceModel>> instancesForScene(
    String sceneId,
  ) async {
    final rows = await (select(
      sceneAssetInstances,
    )..where((row) => row.sceneId.equals(sceneId))).get();
    return [
      for (final row in rows)
        domain.SceneAssetInstanceModel(
          id: row.id,
          sceneId: row.sceneId,
          assetId: row.assetId,
          assetType: domain.SceneAssetType.values.byName(row.assetType),
          stateId: row.stateId,
          parentInstanceId: row.parentInstanceId,
          contextPriority: domain.SceneContextPriority.values.byName(
            row.contextPriority,
          ),
          notes: row.notes,
        ),
    ];
  }

  Future<void> saveTransform(domain.SceneInstanceTransformModel v) =>
      into(sceneInstanceTransforms).insertOnConflictUpdate(
        SceneInstanceTransformsCompanion.insert(
          instanceId: v.instanceId,
          positionX: Value(v.positionX),
          positionY: Value(v.positionY),
          positionZ: Value(v.positionZ),
          rotationX: Value(v.rotationX),
          rotationY: Value(v.rotationY),
          rotationZ: Value(v.rotationZ),
        ),
      );
  Future<domain.SceneInstanceTransformModel?> getTransform(String id) async {
    final r = await (select(
      sceneInstanceTransforms,
    )..where((x) => x.instanceId.equals(id))).getSingleOrNull();
    return r == null
        ? null
        : domain.SceneInstanceTransformModel(
            instanceId: r.instanceId,
            positionX: r.positionX,
            positionY: r.positionY,
            positionZ: r.positionZ,
            rotationX: r.rotationX,
            rotationY: r.rotationY,
            rotationZ: r.rotationZ,
          );
  }

  Future<void> setProperty({
    required String instanceId,
    required String key,
    required String value,
  }) async {
    final existing =
        await (select(sceneInstanceProperties)..where(
              (x) => x.instanceId.equals(instanceId) & x.key.equals(key),
            ))
            .getSingleOrNull();
    await into(sceneInstanceProperties).insertOnConflictUpdate(
      SceneInstancePropertiesCompanion.insert(
        id: existing?.id ?? const Uuid().v4(),
        instanceId: instanceId,
        key: key,
        value: value,
      ),
    );
  }

  Future<Map<String, String>> propertiesFor(String id) async => {
    for (final r in await (select(
      sceneInstanceProperties,
    )..where((x) => x.instanceId.equals(id))).get())
      r.key: r.value,
  };
  Future<domain.SceneContinuitySnapshotModel> captureSnapshot({
    required String sceneId,
    required String instanceId,
    required DateTime createdAt,
  }) async {
    final instance = await getInstance(instanceId);
    if (instance == null) {
      throw StateError('Scene instance not found: $instanceId');
    }
    final transform = await getTransform(instanceId);
    final props = await propertiesFor(instanceId);
    final data = jsonEncode({
      'assetId': instance.assetId,
      'assetType': instance.assetType.name,
      'stateId': instance.stateId,
      'priority': instance.contextPriority.name,
      'notes': instance.notes,
      'properties': props,
      'transform': transform == null
          ? null
          : {
              'px': transform.positionX,
              'py': transform.positionY,
              'pz': transform.positionZ,
              'rx': transform.rotationX,
              'ry': transform.rotationY,
              'rz': transform.rotationZ,
            },
    });
    final model = domain.SceneContinuitySnapshotModel(
      id: const Uuid().v4(),
      sceneId: sceneId,
      instanceId: instanceId,
      snapshotData: data,
      createdAt: createdAt,
    );
    await into(sceneContinuitySnapshots).insert(
      SceneContinuitySnapshotsCompanion.insert(
        id: model.id,
        sceneId: sceneId,
        instanceId: instanceId,
        snapshotData: data,
        createdAt: createdAt,
      ),
    );
    return model;
  }

  Future<List<domain.SceneContinuitySnapshotModel>> snapshotsForScene(
    String id,
  ) async => [
    for (final r in await (select(
      sceneContinuitySnapshots,
    )..where((x) => x.sceneId.equals(id))).get())
      domain.SceneContinuitySnapshotModel(
        id: r.id,
        sceneId: r.sceneId,
        instanceId: r.instanceId,
        snapshotData: r.snapshotData,
        createdAt: r.createdAt,
      ),
  ];
  Future<void> inheritSnapshot({
    required String snapshotId,
    required String targetSceneId,
    required String newInstanceId,
  }) async {
    final r = await (select(
      sceneContinuitySnapshots,
    )..where((x) => x.id.equals(snapshotId))).getSingle();
    final data = jsonDecode(r.snapshotData) as Map<String, dynamic>;
    final props = (data['properties'] as Map).cast<String, dynamic>();
    await transaction(() async {
      await saveInstance(
        domain.SceneAssetInstanceModel(
          id: newInstanceId,
          sceneId: targetSceneId,
          assetId: data['assetId'] as String,
          assetType: domain.SceneAssetType.values.byName(
            data['assetType'] as String,
          ),
          stateId: data['stateId'] as String?,
          contextPriority: domain.SceneContextPriority.values.byName(
            data['priority'] as String,
          ),
          notes: data['notes'] as String,
        ),
      );
      for (final e in props.entries) {
        await setProperty(
          instanceId: newInstanceId,
          key: e.key,
          value: e.value.toString(),
        );
      }
      final t = data['transform'] as Map<String, dynamic>?;
      if (t != null) {
        await saveTransform(
          domain.SceneInstanceTransformModel(
            instanceId: newInstanceId,
            positionX: (t['px'] as num).toDouble(),
            positionY: (t['py'] as num).toDouble(),
            positionZ: (t['pz'] as num).toDouble(),
            rotationX: (t['rx'] as num).toDouble(),
            rotationY: (t['ry'] as num).toDouble(),
            rotationZ: (t['rz'] as num).toDouble(),
          ),
        );
      }
    });
  }
}
