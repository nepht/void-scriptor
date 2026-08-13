import '../../../database/project/project_database.dart' as db;
import 'package:drift/drift.dart';
import '../../references/application/reference_services.dart';
import '../../references/domain/reference_models.dart';

class ResolvedReferenceImage {
  const ResolvedReferenceImage({
    required this.id,
    required this.type,
    required this.filePath,
    required this.priority,
  });
  final String id;
  final ReferenceType type;
  final String filePath;
  final int priority;
}

class ResolvedReferenceLock {
  const ResolvedReferenceLock({
    required this.type,
    required this.instruction,
    required this.priority,
  });
  final PreservationLockType type;
  final String instruction;
  final int priority;
}

class ReferenceBundle {
  const ReferenceBundle({required this.references, required this.locks});
  final List<ResolvedReferenceImage> references;
  final List<ResolvedReferenceLock> locks;

  List<String> get promptInstructions => locks
      .where((lock) => lock.instruction.trim().isNotEmpty)
      .map((lock) => '[${lock.type.name}] ${lock.instruction}')
      .toList(growable: false);
}

class ReferenceBundleResolver {
  ReferenceBundleResolver(this.database);
  final db.ProjectDatabase database;
  final ReferenceSetResolver _sets = const ReferenceSetResolver();
  final ReferencePrioritySelector _priority = const ReferencePrioritySelector();

  Future<ReferenceBundle> resolve({
    required String assetId,
    String? modeId,
    String? sceneId,
    Iterable<ReferenceModel> modeReferences = const [],
    Iterable<ReferenceModel> sceneReferences = const [],
    int maxReferences = 4,
  }) async {
    final rows = await database.referenceDao.list(ownerAssetId: assetId);
    final references = rows
        .map(
          (row) => ReferenceModel(
            id: row.id,
            projectId: row.projectId,
            ownerAssetId: row.ownerAssetId,
            type: referenceTypeFromStorage(row.type),
            source: referenceSourceFromStorage(row.source),
            name: row.name,
            filePath: row.filePath,
            description: row.description,
            priority: row.priority,
            primary: row.primaryReference,
            enabled: row.enabled,
            contentHash: row.contentHash,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
          ),
        )
        .toList(growable: false);
    final persistedModeReferences = <ReferenceModel>[];
    if (modeId != null) {
      final mode = await database.characterModeDao.getMode(modeId);
      final setId = mode?.referenceSetId;
      if (mode == null || mode.characterId != assetId) {
        throw StateError('Character Mode does not belong to asset: $modeId');
      }
      if (setId != null) {
        final setRows = await database.referenceDao.referencesForSet(setId);
        persistedModeReferences.addAll(setRows.map(_mapReference));
      }
    }
    final persistedSceneReferences = <ReferenceModel>[];
    if (sceneId != null) {
      final scene = await database.storyDao.getScene(sceneId);
      if (scene == null) throw StateError('Scene not found: $sceneId');
      final setId = scene.referenceSetId;
      if (setId != null) {
        final setRows = await database.referenceDao.referencesForSet(setId);
        persistedSceneReferences.addAll(setRows.map(_mapReference));
      }
    }
    final effective = _sets.resolve(
      characterReferences: references,
      modeReferences: [...persistedModeReferences, ...modeReferences],
      sceneReferences: [...persistedSceneReferences, ...sceneReferences],
    );
    final selected = _priority.select(
      references: effective.values,
      maxItems: maxReferences,
    );
    final lockRows =
        await (database.select(database.preservationLocks)
              ..where((row) => row.assetId.equals(assetId))
              ..orderBy([
                (row) => OrderingTerm(
                  expression: row.priority,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    return ReferenceBundle(
      references: selected
          .map(
            (reference) => ResolvedReferenceImage(
              id: reference.id,
              type: reference.type,
              filePath: reference.filePath,
              priority: reference.priority,
            ),
          )
          .toList(growable: false),
      locks: lockRows
          .where((lock) => lock.enabled)
          .map(
            (lock) => ResolvedReferenceLock(
              type: preservationLockTypeFromStorage(lock.type),
              instruction: lock.instruction,
              priority: lock.priority,
            ),
          )
          .toList(growable: false),
    );
  }

  ReferenceModel _mapReference(db.Reference row) => ReferenceModel(
    id: row.id,
    projectId: row.projectId,
    ownerAssetId: row.ownerAssetId,
    type: referenceTypeFromStorage(row.type),
    source: referenceSourceFromStorage(row.source),
    name: row.name,
    filePath: row.filePath,
    description: row.description,
    priority: row.priority,
    primary: row.primaryReference,
    enabled: row.enabled,
    contentHash: row.contentHash,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
