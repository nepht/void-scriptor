enum VfxCategory {
  energy,
  aura,
  particle,
  explosion,
  smoke,
  fire,
  electricity,
  weather,
  portal,
  projectile,
  impact,
  distortion,
  hologram,
  environmental,
  transformation,
  destruction,
  custom,
}

class VfxModel {
  const VfxModel({
    required this.assetId,
    required this.projectId,
    required this.name,
    required this.category,
    this.description = '',
    this.visualBehavior = '',
    this.colorPalette = '',
  });
  final String assetId,
      projectId,
      name,
      description,
      visualBehavior,
      colorPalette;
  final VfxCategory category;
}

class VfxBehaviorProfile {
  const VfxBehaviorProfile({
    this.vfxId = '',
    this.originBehavior = '',
    this.movementBehavior = '',
    this.dissipationBehavior = '',
    this.environmentalInteraction = '',
    this.defaultDurationSeconds,
    this.emitsLight = false,
  });
  final String vfxId,
      originBehavior,
      movementBehavior,
      dissipationBehavior,
      environmentalInteraction;
  final double? defaultDurationSeconds;
  final bool emitsLight;
}

class VfxStateModel {
  const VfxStateModel({
    required this.id,
    required this.vfxId,
    required this.name,
    this.description = '',
    this.referenceSetId,
    this.sortOrder = 0,
  });
  final String id, vfxId, name, description;
  final String? referenceSetId;
  final int sortOrder;
}

class VfxTimelineClipModel {
  const VfxTimelineClipModel({
    required this.id,
    required this.sceneId,
    required this.vfxAssetId,
    required this.startSeconds,
    required this.durationSeconds,
    this.stateId,
    this.attachedInstanceId,
  });
  final String id, sceneId, vfxAssetId;
  final double startSeconds, durationSeconds;
  final String? stateId, attachedInstanceId;
}

class VfxKeyframeModel {
  const VfxKeyframeModel({
    required this.id,
    required this.clipId,
    required this.timeSeconds,
    required this.property,
    required this.value,
  });
  final String id, clipId, property;
  final double timeSeconds, value;
}
