import '../../../database/project/project_database.dart' as db;
import '../domain/ai_context.dart';
import 'preservation_prompt_resolver.dart';
import 'reference_bundle_resolver.dart';
import '../../bible/application/bible_repository.dart';
import '../../bible/application/canon_prompt_context.dart';
import '../../bible/application/relevant_canon_context_resolver.dart';
import '../../assets/domain/asset_type.dart';
import '../../scene_assets/application/scene_asset_instance_repository.dart';
import '../../story/data/story_repository_impl.dart';
import '../../character/domain/character_quick_ref.dart';
import 'ai_scene_asset_context_resolver.dart' as production;

class AiContextResolver {
  AiContextResolver(this.database);
  final db.ProjectDatabase database;
  final PreservationPromptResolver preservation = PreservationPromptResolver();
  late final ReferenceBundleResolver referenceBundles = ReferenceBundleResolver(
    database,
  );
  final RelevantCanonContextResolver canonResolver =
      RelevantCanonContextResolver();
  final CanonPromptContextComposer canonComposer = CanonPromptContextComposer();

  Future<AiContext> resolveScene({
    required String projectId,
    required String sceneId,
  }) async {
    final scene = await database.storyDao.getScene(sceneId);
    if (scene == null) throw StateError('Scene not found: $sceneId');
    final bibleEntries = await BibleRepository(database).listEntries(projectId);
    final canonEntries = canonResolver.resolve(
      bibleEntries,
      projectId: projectId,
      entityIds: {sceneId},
      tags: {sceneId},
    );
    final sceneCharacters = await database.storyDao.getSceneCharacters(sceneId);
    final characters = <AiCharacterContext>[];
    final quickRefs = await _quickReferences(sceneId);
    for (final sceneCharacter in sceneCharacters) {
      final character = await database.characterDao.getCharacter(
        sceneCharacter.characterId,
      );
      if (character == null) continue;
      final identity = await database.characterDao.getIdentity(
        character.assetId,
      );
      final mode = sceneCharacter.modeId == null
          ? null
          : await database.characterModeDao.getMode(sceneCharacter.modeId!);
      final locks = _effectiveLocks(
        identity,
        sceneCharacter.modeId == null
            ? null
            : await database.characterModeDao.getIdentityOverride(
                sceneCharacter.modeId!,
              ),
      );
      final loadout = mode == null
          ? const <String>[]
          : await database.characterModeDao
                .getLoadout(mode.id)
                .then(
                  (entries) => entries
                      .where((entry) => entry.enabled)
                      .map((entry) => entry.assetId)
                      .toList(),
                );
      final referenceBundle = await referenceBundles.resolve(
        assetId: character.assetId,
        maxReferences: 6,
      );
      final wardrobe = <String>[];
      final weapons = <String>[];
      for (final assetId in loadout) {
        final wardrobeRow = await database.wardrobeDao.getWardrobe(assetId);
        if (wardrobeRow != null) {
          wardrobe.add(
            '${wardrobeRow.name}: ${wardrobeRow.description} ${wardrobeRow.primaryMaterial} ${wardrobeRow.fabric}'
                .trim(),
          );
          continue;
        }
        final weaponRow = await database.weaponDao.getWeapon(assetId);
        if (weaponRow != null) {
          weapons.add(
            '${weaponRow.name}: ${weaponRow.description} ${weaponRow.primaryMaterial} ${weaponRow.energyType}'
                .trim(),
          );
        }
      }
      characters.add(
        AiCharacterContext(
          characterId: character.assetId,
          name: character.displayName,
          alias: character.alias,
          modeName: mode?.name,
          identityDescription: _identityDescription(character),
          wardrobeDescription: wardrobe.join('\n'),
          weaponDescription: weapons.join('\n'),
          preservationRules: preservation.resolve(locks),
          referenceBundle: AiReferenceBundle(
            referenceIds: referenceBundle.references
                .map((reference) => reference.id)
                .toList(growable: false),
            lockInstructions: referenceBundle.promptInstructions,
          ),
          quickRef: quickRefs.firstOrNull,
        ),
      );
    }
    final beats = await database.storyDao.getSceneBeats(sceneId);
    final sceneContext = AiSceneContext(
      sceneId: scene.id,
      title: scene.title,
      durationSeconds: scene.estimatedDurationSeconds ?? 0,
      beats: beats
          .map(
            (beat) => AiSceneBeat(
              type: beat.beatType,
              content: beat.content,
              startSeconds: beat.startSecond,
              durationSeconds: beat.durationSeconds,
            ),
          )
          .toList(),
    );
    final environmentContext = await _resolveEnvironment(sceneId);
    final sceneAssetContexts = await _resolveSceneAssets(sceneId);
    final timeline = await database.timelineDao.getTimelineForScene(sceneId);
    AiTimelineContext? timelineContext;
    if (timeline != null) {
      final tracks = await database.timelineDao.getTracks(timeline.id);
      final clips = await database.timelineDao.getClips(timeline.id);
      timelineContext = AiTimelineContext(
        durationSeconds: timeline.durationSeconds,
        sections: clips
            .map(
              (clip) => AiTimelineSection(
                start: clip.startSeconds,
                end: clip.startSeconds + clip.durationSeconds,
                entries: [
                  '${tracks.where((track) => track.id == clip.trackId).map((track) => track.name).firstOrNull ?? clip.clipType}: ${clip.label}',
                ],
              ),
            )
            .toList(),
      );
    }
    return AiContext(
      projectId: projectId,
      characterContexts: characters,
      environmentContext: environmentContext,
      sceneContext: sceneContext,
      timelineContext: timelineContext,
      sceneAssetContexts: sceneAssetContexts,
      canonContext: canonComposer.compose(canonEntries),
    );
  }

  Future<List<AiSceneAssetContext>> _resolveSceneAssets(String sceneId) async {
    final repository = SceneAssetInstanceRepository(database);
    final instances = await repository.instancesForScene(sceneId);
    final candidates = <production.AiSceneAssetCandidate>[];
    for (final instance in instances) {
      final asset = await database.assetDao.getById(instance.assetId);
      if (asset == null) continue;
      final matches = AssetType.values.where((item) => item.name == asset.type);
      if (matches.isEmpty) continue;
      final type = matches.first;
      final properties = await repository.propertiesFor(instance.id);
      final referenceBundle = await referenceBundles.resolve(
        assetId: asset.id,
        maxReferences: 6,
      );
      final storyCritical =
          type == AssetType.prop &&
          (await database.propRepository.getProp(asset.id))?.storyCritical ==
              true;
      candidates.add(
        production.AiSceneAssetCandidate(
          assetId: asset.id,
          name: asset.name,
          type: type,
          priority: instance.contextPriority,
          state: instance.stateId ?? properties.values.firstOrNull,
          storyCritical: storyCritical,
          references: referenceBundle.references
              .map((reference) => reference.id)
              .toList(growable: false),
        ),
      );
    }
    return production.AiSceneAssetContextResolver()
        .resolve(candidates, maxAssets: 8, maxReferences: 12)
        .map(
          (item) => AiSceneAssetContext(
            assetId: item.assetId,
            name: item.name,
            type: item.type.name,
            priority: item.priority.name,
            state: item.state,
            references: item.references,
          ),
        )
        .toList(growable: false);
  }

  /// Quick reference kanonik (145.25): daftar CharacterQuickRef scene.
  Future<List<CharacterQuickRef>> _quickReferences(String sceneId) =>
      StoryRepositoryImpl(
        database: database,
        projectId: '',
      ).quickReferenceForScene(sceneId);

  String _identityDescription(dynamic character) => [
    character.biography,
    character.personality,
    'Hair: ${character.hair}',
    'Eyes: ${character.eyes}',
    'Skin: ${character.skin}',
  ].where((value) => value.toString().trim().isNotEmpty).join('\n');

  PreservationLocks _effectiveLocks(
    db.CharacterIdentityProfile? identity,
    dynamic override,
  ) => PreservationLocks(
    faceLock: override?.faceLock ?? identity?.faceLock ?? false,
    hairLock: override?.hairLock ?? identity?.hairLock ?? false,
    bodyLock: override?.bodyLock ?? identity?.bodyLock ?? false,
    colorLock: override?.colorLock ?? identity?.colorLock ?? false,
    outfitLock: override?.outfitLock ?? identity?.outfitLock ?? false,
    weaponLock: override?.weaponLock ?? identity?.weaponLock ?? false,
  );

  Future<AiEnvironmentContext?> _resolveEnvironment(String sceneId) async {
    final relation = await database.storyDao.getSceneEnvironment(sceneId);
    if (relation == null) return null;
    final environment = await database.environmentDao.getEnvironment(
      relation.environmentId,
    );
    if (environment == null) return null;
    final zones = await database.environmentDao.getZones(environment.assetId);
    final weather = (await database.environmentDao.getWeatherProfiles(
      environment.assetId,
    )).firstOrNull;
    final lighting = (await database.environmentDao.getLightingProfiles(
      environment.assetId,
    )).firstOrNull;
    return AiEnvironmentContext(
      environmentId: environment.assetId,
      name: environment.name,
      zone: zones
          .where((zone) => zone.id == relation.zoneId)
          .map((zone) => zone.name)
          .firstOrNull,
      timeOfDay: relation.timePreset ?? lighting?.timePreset,
      weather: weather?.weatherPreset,
      lighting: lighting?.name,
      atmosphere: environment.description,
      continuity: relation.continuityStateId,
    );
  }
}
