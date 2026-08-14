import 'package:drift/drift.dart';
import '../../../database/project/project_database.dart';
import '../../../database/project/tables/vfx.dart';
import '../domain/vfx_model.dart' as domain;
part 'vfx_repository.g.dart';

@DriftAccessor(
  tables: [
    VfxAssets,
    VfxBehaviorProfiles,
    VfxStates,
    VfxTimelineClips,
    VfxKeyframes,
  ],
)
class VfxRepository extends DatabaseAccessor<ProjectDatabase>
    with _$VfxRepositoryMixin {
  VfxRepository(super.db);
  Future<domain.VfxModel?> getVfx(String id) async {
    final r = await (select(
      vfxAssets,
    )..where((x) => x.assetId.equals(id))).getSingleOrNull();
    return r == null
        ? null
        : domain.VfxModel(
            assetId: r.assetId,
            projectId: r.projectId,
            name: r.name,
            category: domain.VfxCategory.values.byName(r.category),
            description: r.description,
            visualBehavior: r.visualBehavior,
            colorPalette: r.colorPalette,
          );
  }

  Future<domain.VfxBehaviorProfile?> getBehavior(String id) async {
    final r = await (select(
      vfxBehaviorProfiles,
    )..where((x) => x.vfxId.equals(id))).getSingleOrNull();
    return r == null
        ? null
        : domain.VfxBehaviorProfile(
            vfxId: r.vfxId,
            originBehavior: r.originBehavior,
            movementBehavior: r.movementBehavior,
            dissipationBehavior: r.dissipationBehavior,
            environmentalInteraction: r.environmentalInteraction,
            defaultDurationSeconds: r.defaultDurationSeconds,
            emitsLight: r.emitsLight,
          );
  }

  Future<List<domain.VfxStateModel>> statesFor(String id) async {
    final rows =
        await (select(vfxStates)
              ..where((x) => x.vfxId.equals(id))
              ..orderBy([(x) => OrderingTerm.asc(x.sortOrder)]))
            .get();
    return [
      for (final r in rows)
        domain.VfxStateModel(
          id: r.id,
          vfxId: r.vfxId,
          name: r.name,
          description: r.description,
          referenceSetId: r.referenceSetId,
          sortOrder: r.sortOrder,
        ),
    ];
  }

  Future<void> saveClip(domain.VfxTimelineClipModel v) =>
      into(vfxTimelineClips).insertOnConflictUpdate(
        VfxTimelineClipsCompanion.insert(
          id: v.id,
          sceneId: v.sceneId,
          vfxAssetId: v.vfxAssetId,
          startSeconds: v.startSeconds,
          durationSeconds: v.durationSeconds,
          stateId: Value(v.stateId),
          attachedInstanceId: Value(v.attachedInstanceId),
        ),
      );
  Future<List<domain.VfxTimelineClipModel>> clipsForScene(String id) async {
    final rows =
        await (select(vfxTimelineClips)
              ..where((x) => x.sceneId.equals(id))
              ..orderBy([(x) => OrderingTerm.asc(x.startSeconds)]))
            .get();
    return [
      for (final r in rows)
        domain.VfxTimelineClipModel(
          id: r.id,
          sceneId: r.sceneId,
          vfxAssetId: r.vfxAssetId,
          startSeconds: r.startSeconds,
          durationSeconds: r.durationSeconds,
          stateId: r.stateId,
          attachedInstanceId: r.attachedInstanceId,
        ),
    ];
  }

  Future<void> saveKeyframes(List<domain.VfxKeyframeModel> values) => batch(
    (b) => b.insertAllOnConflictUpdate(vfxKeyframes, [
      for (final v in values)
        VfxKeyframesCompanion.insert(
          id: v.id,
          clipId: v.clipId,
          timeSeconds: v.timeSeconds,
          property: v.property,
          value: v.value,
        ),
    ]),
  );
  Future<List<domain.VfxKeyframeModel>> keyframesFor(String id) async {
    final rows =
        await (select(vfxKeyframes)
              ..where((x) => x.clipId.equals(id))
              ..orderBy([(x) => OrderingTerm.asc(x.timeSeconds)]))
            .get();
    return [
      for (final r in rows)
        domain.VfxKeyframeModel(
          id: r.id,
          clipId: r.clipId,
          timeSeconds: r.timeSeconds,
          property: r.property,
          value: r.value,
        ),
    ];
  }
}
