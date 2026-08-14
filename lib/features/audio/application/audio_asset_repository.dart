import 'package:drift/drift.dart';
import '../../../database/project/project_database.dart';
import '../../../database/project/tables/audio_assets.dart';
import '../domain/audio_models.dart' as domain;
part 'audio_asset_repository.g.dart';

@DriftAccessor(
  tables: [
    AudioFiles,
    SoundEffects,
    SoundEffectVariations,
    AmbienceAssets,
    AmbienceLayers,
    AmbienceVariants,
    MusicCues,
    MusicSections,
  ],
)
class AudioAssetRepository extends DatabaseAccessor<ProjectDatabase>
    with _$AudioAssetRepositoryMixin {
  AudioAssetRepository(super.db);
  Future<void> saveAudioFile(domain.AudioFileModel v) =>
      into(audioFiles).insertOnConflictUpdate(
        AudioFilesCompanion.insert(
          id: v.id,
          projectId: v.projectId,
          filePath: v.filePath,
          contentHash: Value(v.contentHash),
          durationSeconds: Value(v.durationSeconds),
          sampleRate: Value(v.sampleRate),
          channels: Value(v.channels),
          createdAt: DateTime.now().toUtc(),
        ),
      );
  Future<void> saveSoundEffect(domain.SoundEffectModel v) =>
      into(soundEffects).insertOnConflictUpdate(
        SoundEffectsCompanion.insert(
          assetId: v.assetId,
          projectId: v.projectId,
          audioFileId: Value(v.audioFileId),
          name: v.name,
          category: v.category.name,
          description: Value(v.description),
          loopable: Value(v.loopable),
        ),
      );
  Future<domain.SoundEffectModel?> getSoundEffect(String id) async {
    final r = await (select(
      soundEffects,
    )..where((x) => x.assetId.equals(id))).getSingleOrNull();
    return r == null
        ? null
        : domain.SoundEffectModel(
            assetId: r.assetId,
            projectId: r.projectId,
            audioFileId: r.audioFileId,
            name: r.name,
            category: domain.SoundEffectCategory.values.byName(r.category),
            description: r.description,
            loopable: r.loopable,
          );
  }

  Future<void> saveSoundEffectVariations(
    List<domain.SoundEffectVariationModel> v,
  ) => batch(
    (b) => b.insertAllOnConflictUpdate(soundEffectVariations, [
      for (final x in v)
        SoundEffectVariationsCompanion.insert(
          id: x.id,
          soundEffectId: x.soundEffectId,
          audioFileId: x.audioFileId,
          label: Value(x.label),
          weight: Value(x.weight),
        ),
    ]),
  );
  Future<List<domain.SoundEffectVariationModel>> variationsFor(
    String id,
  ) async {
    final rows = await (select(
      soundEffectVariations,
    )..where((x) => x.soundEffectId.equals(id))).get();
    return [
      for (final r in rows)
        domain.SoundEffectVariationModel(
          id: r.id,
          soundEffectId: r.soundEffectId,
          audioFileId: r.audioFileId,
          label: r.label,
          weight: r.weight,
        ),
    ];
  }

  Future<void> saveAmbience(domain.AmbienceModel v) =>
      into(ambienceAssets).insertOnConflictUpdate(
        AmbienceAssetsCompanion.insert(
          assetId: v.assetId,
          projectId: v.projectId,
          audioFileId: Value(v.audioFileId),
          name: v.name,
          description: Value(v.description),
          loopable: Value(v.loopable),
        ),
      );
  Future<void> saveAmbienceLayer(domain.AmbienceLayerModel v) =>
      into(ambienceLayers).insertOnConflictUpdate(
        AmbienceLayersCompanion.insert(
          id: v.id,
          ambienceId: v.ambienceId,
          audioFileId: v.audioFileId,
          name: v.name,
          defaultGainDb: Value(v.defaultGainDb),
          sortOrder: Value(v.sortOrder),
        ),
      );
  Future<List<domain.AmbienceLayerModel>> layersFor(String id) async {
    final rows =
        await (select(ambienceLayers)
              ..where((x) => x.ambienceId.equals(id))
              ..orderBy([(x) => OrderingTerm.asc(x.sortOrder)]))
            .get();
    return [
      for (final r in rows)
        domain.AmbienceLayerModel(
          id: r.id,
          ambienceId: r.ambienceId,
          audioFileId: r.audioFileId,
          name: r.name,
          defaultGainDb: r.defaultGainDb,
          sortOrder: r.sortOrder,
        ),
    ];
  }

  Future<void> saveAmbienceVariant(domain.AmbienceVariantModel v) =>
      into(ambienceVariants).insertOnConflictUpdate(
        AmbienceVariantsCompanion.insert(
          id: v.id,
          ambienceId: v.ambienceId,
          name: v.name,
          referenceAudioFileId: Value(v.referenceAudioFileId),
          conditions: Value(v.conditions),
        ),
      );
  Future<List<domain.AmbienceVariantModel>> variantsFor(String id) async {
    final rows = await (select(
      ambienceVariants,
    )..where((x) => x.ambienceId.equals(id))).get();
    return [
      for (final r in rows)
        domain.AmbienceVariantModel(
          id: r.id,
          ambienceId: r.ambienceId,
          name: r.name,
          referenceAudioFileId: r.referenceAudioFileId,
          conditions: r.conditions,
        ),
    ];
  }

  Future<void> saveMusic(domain.MusicCueModel v) =>
      into(musicCues).insertOnConflictUpdate(
        MusicCuesCompanion.insert(
          assetId: v.assetId,
          projectId: v.projectId,
          audioFileId: Value(v.audioFileId),
          name: v.name,
          mood: v.mood.name,
          bpm: Value(v.bpm),
          musicalKey: Value(v.musicalKey),
          description: Value(v.description),
          loopable: Value(v.loopable),
        ),
      );
  Future<domain.MusicCueModel?> getMusic(String id) async {
    final r = await (select(
      musicCues,
    )..where((x) => x.assetId.equals(id))).getSingleOrNull();
    return r == null
        ? null
        : domain.MusicCueModel(
            assetId: r.assetId,
            projectId: r.projectId,
            audioFileId: r.audioFileId,
            name: r.name,
            mood: domain.MusicMood.values.byName(r.mood),
            bpm: r.bpm,
            musicalKey: r.musicalKey,
            description: r.description,
            loopable: r.loopable,
          );
  }

  Future<void> saveMusicSection(domain.MusicSectionModel v) =>
      into(musicSections).insertOnConflictUpdate(
        MusicSectionsCompanion.insert(
          id: v.id,
          musicId: v.musicId,
          name: v.name,
          startSeconds: v.startSeconds,
          endSeconds: v.endSeconds,
          mood: Value(v.mood?.name),
        ),
      );
  Future<List<domain.MusicSectionModel>> sectionsFor(String id) async {
    final rows =
        await (select(musicSections)
              ..where((x) => x.musicId.equals(id))
              ..orderBy([(x) => OrderingTerm.asc(x.startSeconds)]))
            .get();
    return [
      for (final r in rows)
        domain.MusicSectionModel(
          id: r.id,
          musicId: r.musicId,
          name: r.name,
          startSeconds: r.startSeconds,
          endSeconds: r.endSeconds,
          mood: r.mood == null ? null : domain.MusicMood.values.byName(r.mood!),
        ),
    ];
  }
}
