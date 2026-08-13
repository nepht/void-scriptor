enum SceneAssetType {
  character,
  creature,
  vehicle,
  prop,
  weapon,
  wardrobe,
  environment,
}

enum SceneContextPriority { critical, high, normal, optional }

class SceneAssetInstanceModel {
  const SceneAssetInstanceModel({
    required this.id,
    required this.sceneId,
    required this.assetId,
    required this.assetType,
    this.stateId,
    this.parentInstanceId,
    this.contextPriority = SceneContextPriority.normal,
    this.notes = '',
  });
  final String id, sceneId, assetId, notes;
  final SceneAssetType assetType;
  final String? stateId, parentInstanceId;
  final SceneContextPriority contextPriority;
}

class SceneInstanceTransformModel {
  const SceneInstanceTransformModel({
    required this.instanceId,
    this.positionX = 0,
    this.positionY = 0,
    this.positionZ = 0,
    this.rotationX = 0,
    this.rotationY = 0,
    this.rotationZ = 0,
  });
  final String instanceId;
  final double positionX, positionY, positionZ, rotationX, rotationY, rotationZ;
}

class SceneContinuitySnapshotModel {
  const SceneContinuitySnapshotModel({
    required this.id,
    required this.sceneId,
    required this.instanceId,
    required this.snapshotData,
    required this.createdAt,
  });
  final String id, sceneId, instanceId, snapshotData;
  final DateTime createdAt;
}

class SceneContinuityValidator {
  List<String> compare({
    required Map<String, String> previous,
    required Map<String, String> current,
    required Set<String> transitions,
  }) {
    final result = <String>[];
    for (final entry in previous.entries) {
      final next = current[entry.key];
      if (next != null &&
          next != entry.value &&
          !transitions.contains(entry.key)) {
        result.add(
          '${entry.key} changed: ${entry.value} → $next without recorded transition',
        );
      }
    }
    return result;
  }
}
