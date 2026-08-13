enum ReferenceType {
  face,
  hair,
  body,
  fullBody,
  wardrobe,
  weapon,
  accessory,
  environment,
  pose,
  expression,
  material,
  style,
  lighting,
  other,
}

enum ReferenceSource { imported, generated, captured, linkedAsset }

enum PreservationLockType {
  face,
  hairGeometry,
  bodyTopology,
  wardrobeGeometry,
  weaponGeometry,
  creatureGeometry,
  vehicleGeometry,
  propGeometry,
  material,
  color,
  accessories,
  environmentGeometry,
  landmark,
  lightingContinuity,
}

enum ConsistencyRuleType {
  identity,
  hair,
  wardrobe,
  weapon,
  color,
  accessory,
  environment,
  custom,
}

enum ConsistencySeverity { info, warning, critical }

enum ConsistencyReviewStatus { notReviewed, passed, reviewRequired, failed }

enum ReferenceHealth { healthy, incomplete, missing, moved, modified, broken }

enum ImageComparisonMode { sideBySide, overlay, swipe }

class ReferenceModel {
  const ReferenceModel({
    required this.id,
    required this.projectId,
    required this.type,
    required this.source,
    required this.name,
    required this.filePath,
    required this.priority,
    required this.primary,
    required this.enabled,
    this.ownerAssetId,
    this.description = '',
    this.contentHash,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String projectId;
  final String? ownerAssetId;
  final ReferenceType type;
  final ReferenceSource source;
  final String name;
  final String filePath;
  final String description;
  final int priority;
  final bool primary;
  final bool enabled;
  final String? contentHash;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class ReferenceSetModel {
  const ReferenceSetModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.defaultSet,
    this.ownerAssetId,
    this.description = '',
    this.referenceIds = const [],
    this.createdAt,
  });

  final String id;
  final String projectId;
  final String? ownerAssetId;
  final String name;
  final String description;
  final bool defaultSet;
  final List<String> referenceIds;
  final DateTime? createdAt;
}

class CharacterIdentityProfileModel {
  const CharacterIdentityProfileModel({
    required this.characterId,
    this.faceLock = true,
    this.hairLock = true,
    this.bodyLock = true,
    this.colorLock = true,
    this.accessoryLock = false,
    this.notes = '',
  });

  final String characterId;
  final bool faceLock;
  final bool hairLock;
  final bool bodyLock;
  final bool colorLock;
  final bool accessoryLock;
  final String notes;
}

class PreservationLockModel {
  const PreservationLockModel({
    required this.id,
    required this.assetId,
    required this.type,
    required this.enabled,
    required this.priority,
    this.instruction = '',
  });

  final String id;
  final String assetId;
  final PreservationLockType type;
  final bool enabled;
  final String instruction;
  final int priority;
}

class ConsistencyRuleModel {
  const ConsistencyRuleModel({
    required this.id,
    required this.assetId,
    required this.type,
    required this.description,
    required this.severity,
    this.enabled = true,
  });

  final String id;
  final String assetId;
  final ConsistencyRuleType type;
  final String description;
  final ConsistencySeverity severity;
  final bool enabled;
}

class ConsistencyReviewModel {
  const ConsistencyReviewModel({
    required this.id,
    required this.generationOutputId,
    required this.assetId,
    required this.status,
    this.notes = '',
    this.reviewedAt,
  });

  final String id;
  final String generationOutputId;
  final String assetId;
  final ConsistencyReviewStatus status;
  final String notes;
  final DateTime? reviewedAt;
}

class ConsistencyReviewItemModel {
  const ConsistencyReviewItemModel({
    required this.id,
    required this.reviewId,
    required this.ruleId,
    required this.status,
    this.notes = '',
  });

  final String id;
  final String reviewId;
  final String ruleId;
  final ConsistencyReviewStatus status;
  final String notes;
}

class ComparisonViewport {
  const ComparisonViewport({
    this.scale = 1,
    this.offsetX = 0,
    this.offsetY = 0,
  });
  final double scale;
  final double offsetX;
  final double offsetY;
}

ReferenceType referenceTypeFromStorage(String value) =>
    ReferenceType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ReferenceType.other,
    );

ReferenceSource referenceSourceFromStorage(String value) =>
    ReferenceSource.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ReferenceSource.imported,
    );

PreservationLockType preservationLockTypeFromStorage(String value) =>
    PreservationLockType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => PreservationLockType.face,
    );

ConsistencyRuleType consistencyRuleTypeFromStorage(String value) =>
    ConsistencyRuleType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ConsistencyRuleType.custom,
    );
