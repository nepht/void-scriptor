import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../../core/persistence/project_paths.dart';
import '../../../database/project/project_database.dart';
import '../../../database/project/tables/consistency.dart';
import '../../../database/project/tables/character_modes.dart';
import '../../../database/project/tables/reference_identity.dart';
import '../../../database/project/tables/reference_sets.dart';
import '../../../database/project/tables/references.dart';
import '../../../database/project/tables/story_scenes.dart';
import '../domain/reference_models.dart';

part 'reference_repository.g.dart';

@DriftAccessor(
  tables: [
    References,
    ReferenceSets,
    ReferenceSetItems,
    ReferenceVersions,
    PreservationLocks,
    ConsistencyRules,
    ConsistencyReviews,
    ConsistencyReviewItems,
    CharacterModes,
    StoryScenes,
  ],
)
class ReferenceDao extends DatabaseAccessor<ProjectDatabase>
    with _$ReferenceDaoMixin {
  ReferenceDao(super.db);

  Future<List<Reference>> list({
    String? projectId,
    String? ownerAssetId,
    ReferenceType? type,
  }) {
    final query = select(references);
    if (projectId != null) {
      query.where((row) => row.projectId.equals(projectId));
    }
    if (ownerAssetId != null) {
      query.where((row) => row.ownerAssetId.equals(ownerAssetId));
    }
    if (type != null) query.where((row) => row.type.equals(type.name));
    query.orderBy([
      (row) => OrderingTerm(
        expression: row.primaryReference,
        mode: OrderingMode.desc,
      ),
      (row) => OrderingTerm(expression: row.priority, mode: OrderingMode.desc),
    ]);
    return query.get();
  }

  Future<Reference?> byId(String id) =>
      (select(references)..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<Reference?> byContentHash(String projectId, String hash) =>
      (select(references)..where(
            (row) =>
                row.projectId.equals(projectId) & row.contentHash.equals(hash),
          ))
          .getSingleOrNull();

  Future<void> insertReference({required ReferenceModel reference}) =>
      into(references).insertOnConflictUpdate(
        ReferencesCompanion.insert(
          id: reference.id,
          projectId: reference.projectId,
          ownerAssetId: Value(reference.ownerAssetId),
          type: reference.type.name,
          source: reference.source.name,
          name: reference.name,
          filePath: reference.filePath,
          description: Value(reference.description),
          priority: Value(reference.priority),
          primaryReference: Value(reference.primary),
          enabled: Value(reference.enabled),
          contentHash: Value(reference.contentHash),
          createdAt: reference.createdAt ?? DateTime.now().toUtc(),
          updatedAt: reference.updatedAt ?? DateTime.now().toUtc(),
        ),
      );

  Future<void> setPrimary({
    required String projectId,
    required String? ownerAssetId,
    required ReferenceType type,
    required String referenceId,
  }) async {
    await transaction(() async {
      await (update(references)..where((row) {
            final owner = ownerAssetId == null
                ? row.ownerAssetId.isNull()
                : row.ownerAssetId.equals(ownerAssetId);
            return row.projectId.equals(projectId) &
                row.type.equals(type.name) &
                owner;
          }))
          .write(const ReferencesCompanion(primaryReference: Value(false)));
      final target = await byId(referenceId);
      if (target == null ||
          target.projectId != projectId ||
          target.type != type.name ||
          target.ownerAssetId != ownerAssetId) {
        throw StateError(
          'Reference does not match primary scope: $referenceId',
        );
      }
      await (update(
        references,
      )..where((row) => row.id.equals(referenceId))).write(
        ReferencesCompanion(
          primaryReference: const Value(true),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
    });
  }

  Future<void> addToSet({
    required String setId,
    required String referenceId,
    int sortOrder = 0,
  }) => into(referenceSetItems).insertOnConflictUpdate(
    ReferenceSetItemsCompanion.insert(
      referenceSetId: setId,
      referenceId: referenceId,
      sortOrder: Value(sortOrder),
    ),
  );

  Future<List<ReferenceSetItem>> itemsForSet(String setId) =>
      (select(referenceSetItems)
            ..where((row) => row.referenceSetId.equals(setId))
            ..orderBy([(row) => OrderingTerm(expression: row.sortOrder)]))
          .get();

  Future<void> saveSet(ReferenceSetModel set) =>
      into(referenceSets).insertOnConflictUpdate(
        ReferenceSetsCompanion.insert(
          id: set.id,
          projectId: set.projectId,
          ownerAssetId: Value(set.ownerAssetId),
          name: set.name,
          description: Value(set.description),
          defaultSet: Value(set.defaultSet),
          createdAt: set.createdAt ?? DateTime.now().toUtc(),
        ),
      );

  Future<List<ReferenceSet>> setsForOwner(String projectId, String? ownerId) =>
      (select(referenceSets)..where((row) {
            final owner = ownerId == null
                ? row.ownerAssetId.isNull()
                : row.ownerAssetId.equals(ownerId);
            return row.projectId.equals(projectId) & owner;
          }))
          .get();

  Future<void> removeFromSet(String setId, String referenceId) =>
      (delete(referenceSetItems)..where(
            (row) =>
                row.referenceSetId.equals(setId) &
                row.referenceId.equals(referenceId),
          ))
          .go();

  Future<List<Reference>> referencesForSet(String setId) async {
    final items = await itemsForSet(setId);
    final result = <Reference>[];
    for (final item in items) {
      final reference = await byId(item.referenceId);
      if (reference != null && reference.enabled) result.add(reference);
    }
    return result;
  }

  Future<void> saveLock(PreservationLockModel lock) =>
      into(preservationLocks).insertOnConflictUpdate(
        PreservationLocksCompanion.insert(
          id: lock.id,
          assetId: lock.assetId,
          type: lock.type.name,
          enabled: Value(lock.enabled),
          instruction: Value(lock.instruction),
          priority: Value(lock.priority),
        ),
      );

  Future<List<PreservationLock>> locksForAsset(String assetId) =>
      (select(preservationLocks)
            ..where((row) => row.assetId.equals(assetId))
            ..orderBy([(row) => OrderingTerm.desc(row.priority)]))
          .get();

  Future<void> saveRule(ConsistencyRuleModel rule) =>
      into(consistencyRules).insertOnConflictUpdate(
        ConsistencyRulesCompanion.insert(
          id: rule.id,
          assetId: rule.assetId,
          type: rule.type.name,
          description: rule.description,
          severity: rule.severity.name,
          enabled: Value(rule.enabled),
        ),
      );

  Future<List<ConsistencyRule>> rulesForAsset(String assetId) =>
      (select(consistencyRules)..where(
            (row) => row.assetId.equals(assetId) & row.enabled.equals(true),
          ))
          .get();

  Future<List<ConsistencyReview>> reviewsForAsset(String assetId) =>
      (select(consistencyReviews)
            ..where((row) => row.assetId.equals(assetId))
            ..orderBy([(row) => OrderingTerm.desc(row.reviewedAt)]))
          .get();

  Future<void> assignSetToMode(String modeId, String? setId) =>
      (update(characterModes)..where((row) => row.id.equals(modeId))).write(
        CharacterModesCompanion(referenceSetId: Value(setId)),
      );

  Future<void> assignSetToScene(String sceneId, String? setId) =>
      (update(storyScenes)..where((row) => row.id.equals(sceneId))).write(
        StoryScenesCompanion(referenceSetId: Value(setId)),
      );

  Future<void> saveReview(ConsistencyReviewModel review) =>
      into(consistencyReviews).insertOnConflictUpdate(
        ConsistencyReviewsCompanion.insert(
          id: review.id,
          generationOutputId: review.generationOutputId,
          assetId: review.assetId,
          status: review.status.name,
          notes: Value(review.notes),
          reviewedAt: Value(review.reviewedAt),
        ),
      );

  Future<void> saveReviewItem(ConsistencyReviewItemModel item) =>
      into(consistencyReviewItems).insertOnConflictUpdate(
        ConsistencyReviewItemsCompanion.insert(
          id: item.id,
          reviewId: item.reviewId,
          ruleId: item.ruleId,
          status: item.status.name,
          note: Value(item.notes),
        ),
      );

  Future<List<ConsistencyReviewItem>> itemsForReview(String reviewId) =>
      (select(
        consistencyReviewItems,
      )..where((row) => row.reviewId.equals(reviewId))).get();

  Future<void> saveVersion({
    required String referenceId,
    required String filePath,
    required String? contentHash,
    required String changeNote,
  }) async {
    final versions = await (select(
      referenceVersions,
    )..where((row) => row.referenceId.equals(referenceId))).get();
    await into(referenceVersions).insert(
      ReferenceVersionsCompanion.insert(
        id: '$referenceId-v${versions.length + 1}',
        referenceId: referenceId,
        version: versions.length + 1,
        filePath: filePath,
        contentHash: Value(contentHash),
        changeNote: Value(changeNote),
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<ReferenceVersion?> versionById(String id) => (select(
    referenceVersions,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<int> nextVersion(String referenceId) async =>
      (await (select(
        referenceVersions,
      )..where((row) => row.referenceId.equals(referenceId))).get()).length +
      1;
}

class ReferenceImportService {
  ReferenceImportService({required this.database, required this.paths})
    : dao = ReferenceDao(database);
  final ProjectDatabase database;
  final ProjectPaths paths;
  final ReferenceDao dao;

  Future<ReferenceModel> importFile({
    required String projectId,
    required String referenceId,
    required String sourcePath,
    required String name,
    required ReferenceType type,
    String? ownerAssetId,
    ReferenceSource source = ReferenceSource.imported,
    int priority = 0,
    bool primary = false,
    String description = '',
    bool allowDuplicate = false,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw StateError('Reference source file not found: $sourcePath');
    }
    final projectDir = await paths.project(projectId);
    final targetDir = Directory(
      p.join(
        projectDir.path,
        'assets',
        'references',
        ownerAssetId ?? 'unowned',
        type.name,
      ),
    );
    await targetDir.create(recursive: true);
    final target = File(
      p.join(targetDir.path, '${referenceId}_${p.basename(sourcePath)}'),
    );
    await sourceFile.copy(target.path);
    final hash = sha256.convert(await target.readAsBytes()).toString();
    final duplicate = await dao.byContentHash(projectId, hash);
    if (!allowDuplicate && duplicate != null && duplicate.id != referenceId) {
      await target.delete();
      throw StateError(
        'Reference already exists: ${duplicate.name} (${duplicate.id})',
      );
    }
    final now = DateTime.now().toUtc();
    final model = ReferenceModel(
      id: referenceId,
      projectId: projectId,
      ownerAssetId: ownerAssetId,
      type: type,
      source: source,
      name: name,
      filePath: p.relative(target.path, from: projectDir.path),
      description: description,
      priority: priority,
      primary: primary,
      enabled: true,
      contentHash: hash,
      createdAt: now,
      updatedAt: now,
    );
    await dao.insertReference(reference: model);
    if (primary) {
      await dao.setPrimary(
        projectId: projectId,
        ownerAssetId: ownerAssetId,
        type: type,
        referenceId: referenceId,
      );
    }
    return model;
  }

  Future<ReferenceModel> replaceFile({
    required String projectId,
    required String referenceId,
    required String sourcePath,
    String changeNote = '',
  }) async {
    final current = await dao.byId(referenceId);
    if (current == null) throw StateError('Reference not found: $referenceId');
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('Replacement file not found: $sourcePath');
    }
    final projectDir = await paths.project(projectId);
    final target = File(p.join(projectDir.path, current.filePath));
    await target.parent.create(recursive: true);
    // vs-hunt-20260913-references REF-BUG-1: the stored file may be missing on
    // disk (external deletion, moved drive). Snapshot only when there is a
    // previous version to preserve; otherwise replacing recovers the row
    // instead of throwing an unhandled FileSystemException.
    final hasPreviousFile = await target.exists();
    File? snapshot;
    if (hasPreviousFile) {
      final versionNumber = await dao.nextVersion(referenceId);
      snapshot = File(
        p.join(
          target.parent.path,
          'versions',
          'v${versionNumber}_${p.basename(target.path)}',
        ),
      );
      await snapshot.parent.create(recursive: true);
      await target.copy(snapshot.path);
    }
    await source.copy(target.path);
    final hash = sha256.convert(await target.readAsBytes()).toString();
    if (snapshot != null) {
      await dao.saveVersion(
        referenceId: referenceId,
        filePath: p.relative(snapshot.path, from: projectDir.path),
        contentHash: current.contentHash,
        changeNote: changeNote,
      );
    }
    await (database.update(
      database.references,
    )..where((row) => row.id.equals(referenceId))).write(
      ReferencesCompanion(
        contentHash: Value(hash),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    final updated = await dao.byId(referenceId);
    return ReferenceModel(
      id: updated!.id,
      projectId: updated.projectId,
      ownerAssetId: updated.ownerAssetId,
      type: referenceTypeFromStorage(updated.type),
      source: referenceSourceFromStorage(updated.source),
      name: updated.name,
      filePath: updated.filePath,
      description: updated.description,
      priority: updated.priority,
      primary: updated.primaryReference,
      enabled: updated.enabled,
      contentHash: updated.contentHash,
      createdAt: updated.createdAt,
      updatedAt: updated.updatedAt,
    );
  }

  Future<ReferenceModel> restoreVersion({
    required String projectId,
    required String referenceId,
    required String versionId,
  }) async {
    final current = await dao.byId(referenceId);
    final version = await dao.versionById(versionId);
    if (current == null || current.projectId != projectId) {
      throw StateError('Reference not found: $referenceId');
    }
    if (version == null || version.referenceId != referenceId) {
      throw StateError('Reference version not found: $versionId');
    }
    final projectDir = await paths.project(projectId);
    final snapshot = File(p.join(projectDir.path, version.filePath));
    if (!await snapshot.exists()) {
      throw StateError(
        'Reference version file is missing: ${version.filePath}',
      );
    }
    final currentFile = File(p.join(projectDir.path, current.filePath));
    await currentFile.parent.create(recursive: true);
    await snapshot.copy(currentFile.path);
    final hash = sha256.convert(await currentFile.readAsBytes()).toString();
    await (database.update(
      database.references,
    )..where((row) => row.id.equals(referenceId))).write(
      ReferencesCompanion(
        contentHash: Value(hash),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    final restored = await dao.byId(referenceId);
    return ReferenceModel(
      id: restored!.id,
      projectId: restored.projectId,
      ownerAssetId: restored.ownerAssetId,
      type: referenceTypeFromStorage(restored.type),
      source: referenceSourceFromStorage(restored.source),
      name: restored.name,
      filePath: restored.filePath,
      description: restored.description,
      priority: restored.priority,
      primary: restored.primaryReference,
      enabled: restored.enabled,
      contentHash: restored.contentHash,
      createdAt: restored.createdAt,
      updatedAt: restored.updatedAt,
    );
  }
}
