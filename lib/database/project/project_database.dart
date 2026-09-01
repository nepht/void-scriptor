import 'package:drift/drift.dart';
import 'tables/asset_tags.dart';
import 'tables/asset_relations.dart';
import 'tables/assets.dart';
import 'tables/character_identity_profiles.dart';
import 'tables/character_references.dart';
import 'tables/character_modes.dart';
import 'tables/character_loadout_entries.dart';
import 'tables/character_mode_identity_overrides.dart';
import 'tables/character_mode_references.dart';
import 'tables/environments.dart';
import 'tables/environment_zones.dart';
import 'tables/environment_architectures.dart';
import 'tables/environment_weather_profiles.dart';
import 'tables/environment_lighting_profiles.dart';
import 'tables/environment_colors.dart';
import 'tables/environment_props.dart';
import 'tables/environment_continuity_states.dart';
import 'tables/environment_physics_profiles.dart';
import 'tables/environment_references.dart';
import 'tables/stories.dart';
import 'tables/story_arcs.dart';
import 'tables/story_chapters.dart';
import 'tables/story_scenes.dart';
import 'tables/scene_characters.dart';
import 'tables/scene_environment_contexts.dart';
import 'tables/scene_beats.dart';
import 'tables/scene_draft_snapshots.dart';
import 'tables/scene_continuity_changes.dart';
import 'tables/story_bible_sections.dart';
import 'tables/timelines.dart';
import 'tables/timeline_tracks.dart';
import 'tables/timeline_clips.dart';
import 'daos/timeline_dao.dart';
import 'tables/prompt_templates.dart';
import 'tables/ai_prompt_history.dart';
import 'tables/prompt_revisions.dart';
import 'tables/ai_generations.dart';
import 'tables/ai_generation_jobs.dart';
import 'tables/ai_generation_outputs.dart';
import 'tables/ai_generation_inputs.dart';
import 'tables/tags.dart';
import 'tables/asset_collections.dart';
import 'tables/references.dart';
import 'tables/reference_sets.dart';
import 'tables/reference_identity.dart';
import 'tables/consistency.dart';
import 'tables/bible_entries.dart';
import 'tables/canon_rules.dart';
import 'tables/factions.dart';
import 'tables/faction_units.dart';
import 'tables/canon_conflicts.dart';
import 'tables/worldbuilding_entities.dart';
import 'tables/bible_timeline.dart';
import 'tables/creatures.dart';
import 'tables/creature_ecology_states.dart';
import 'tables/vehicles.dart';
import 'tables/props.dart';
import 'tables/scene_asset_instances.dart';
import 'tables/vfx.dart';
import 'tables/audio_assets.dart';
import 'tables/dialogue.dart';
import 'tables/audio_timeline.dart';
import 'tables/audio_waveform.dart';
import 'tables/project_resilience.dart';
import 'tables/command_history_entries.dart';
import 'tables/background_jobs.dart';
import 'tables/job_dependencies.dart';
import 'tables/layout_presets.dart';
import 'tables/project_layout_states.dart';
import 'tables/ai_usage_logs.dart';
import 'tables/ai_model_catalog.dart';
import 'tables/ai_output_reviews.dart';
import 'tables/sync_logs.dart';
import 'tables/sync_conflicts.dart';
import 'tables/project_collaborators.dart';
import 'tables/project_comments.dart';
import 'tables/activity_events.dart';
import 'tables/security_settings.dart';
import 'tables/plugins.dart';
import 'tables/animation.dart';
import 'tables/audio_automation_curves.dart';
import 'tables/shots.dart';
import 'tables/publish_records.dart';
import 'tables/studio.dart';
import 'tables/knowledge.dart';
import 'tables/agents.dart';
import 'tables/creative.dart';
import 'tables/xr.dart';
import 'tables/metaverse.dart';
import 'tables/characters.dart';
import 'tables/novel_character_links.dart';
import 'tables/workflow_persistence.dart';
import 'tables/wardrobes.dart';
import 'tables/wardrobe_components.dart';
import 'tables/wardrobe_colors.dart';
import 'tables/wardrobe_variants.dart';
import 'tables/wardrobe_references.dart';
import 'tables/weapons.dart';
import 'tables/weapon_components.dart';
import 'tables/weapon_measurements.dart';
import 'tables/weapon_colors.dart';
import 'tables/weapon_energy_profiles.dart';
import 'tables/weapon_variants.dart';
import 'tables/weapon_references.dart';
import 'tables/weapon_preservation_profiles.dart';
import 'daos/asset_dao.dart';
import 'daos/character_dao.dart';
import 'daos/character_mode_dao.dart';
import 'daos/relation_dao.dart';
import 'daos/background_job_dao.dart';
import 'daos/wardrobe_dao.dart';
import 'daos/weapon_dao.dart';
import 'daos/environment_dao.dart';
import 'daos/story_dao.dart';
import '../../features/references/application/reference_repository.dart';
import '../../features/bible/application/bible_repository.dart';
import '../../features/bible/application/canon_rule_repository.dart';
import '../../features/bible/application/faction_repository.dart';
import '../../features/bible/application/worldbuilding_repository.dart';
import '../../features/bible/application/bible_timeline_repository.dart';
import '../../features/bible/application/canon_conflict_repository.dart';
import '../../features/creatures/data/creature_repository.dart';
import '../../features/vehicles/data/vehicle_repository.dart';
import '../../features/props/data/prop_repository.dart';
import '../../features/scene_assets/application/scene_asset_instance_repository.dart';
import '../../features/vfx/data/vfx_repository.dart';
import '../../features/audio/application/audio_asset_repository.dart';
import '../../features/dialogue/application/dialogue_repository.dart';
import '../../features/audio_timeline/application/audio_timeline_repository.dart';
import '../../features/audio_import/application/audio_import_repository.dart';
import '../../features/project_resilience/application/project_resilience_repository.dart';

part 'project_database.g.dart';

class ProjectMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    ProjectMetadata,
    Assets,
    AssetTags,
    Characters,
    NovelCharacterLinks,
    WorkflowDefinitions,
    WorkflowRunRecords,
    CharacterIdentityProfiles,
    CharacterReferences,
    CharacterModes,
    CharacterLoadoutEntries,
    CharacterModeIdentityOverrides,
    CharacterModeReferences,
    AssetRelations,
    Wardrobes,
    WardrobeComponents,
    WardrobeColors,
    WardrobeVariants,
    WardrobeReferences,
    Weapons,
    WeaponComponents,
    WeaponMeasurements,
    WeaponColors,
    WeaponEnergyProfiles,
    WeaponVariants,
    WeaponReferences,
    WeaponPreservationProfiles,
    Environments,
    EnvironmentZones,
    EnvironmentArchitectures,
    EnvironmentWeatherProfiles,
    EnvironmentLightingProfiles,
    EnvironmentColors,
    EnvironmentProps,
    EnvironmentContinuityStates,
    EnvironmentPhysicsProfiles,
    EnvironmentReferences,
    Stories,
    StoryArcs,
    StoryChapters,
    StoryScenes,
    SceneCharacters,
    SceneEnvironmentContexts,
    SceneBeats,
    SceneDraftSnapshots,
    SceneContinuityChanges,
    StoryBibleSections,
    Timelines,
    TimelineTracks,
    TimelineClips,
    PromptTemplates,
    AiPromptHistory,
    PromptRevisions,
    AiGenerations,
    AiGenerationJobs,
    AiGenerationOutputs,
    AiGenerationInputs,
    Tags,
    AssetTagLinks,
    AssetCollections,
    AssetCollectionItems,
    References,
    ReferenceSets,
    ReferenceSetItems,
    ReferenceVersions,
    PreservationLocks,
    ConsistencyRules,
    ConsistencyReviews,
    ConsistencyReviewItems,
    BibleEntries,
    CanonRules,
    CanonRuleConditions,
    Factions,
    FactionUnits,
    CanonConflicts,
    CanonRuleExceptions,
    Species,
    Technologies,
    PowerSystems,
    PowerAbilities,
    TerminologyEntries,
    TimelineEras,
    HistoricalEvents,
    HistoricalEventParticipants,
    Creatures,
    CreaturePhysicalProfiles,
    CreatureAbilities,
    CreatureModes,
    CreatureEcologyStates,
    Vehicles,
    VehicleSpecifications,
    VehicleComponents,
    VehicleWeaponMounts,
    VehicleVariants,
    Props,
    PropSpecifications,
    PropStates,
    SceneAssetInstances,
    SceneInstanceTransforms,
    SceneInstanceProperties,
    SceneContinuitySnapshots,
    VfxAssets,
    VfxBehaviorProfiles,
    VfxStates,
    VfxTimelineClips,
    VfxKeyframes,
    AudioFiles,
    SoundEffects,
    SoundEffectVariations,
    AmbienceAssets,
    AmbienceLayers,
    AmbienceVariants,
    MusicCues,
    MusicSections,
    VoiceProfiles,
    VoiceReferences,
    DialogueLines,
    DialogueTakes,
    AudioTimelineClips,
    AudioAutomationKeyframes,
    AudioWaveformCaches,
    ExternalFiles,
    ProjectBackups,
    CacheEntries,
    TrashEntries,
    ProjectMigrationHistory,
    CommandHistoryEntries,
    BackgroundJobs,
    JobDependencies,
    LayoutPresets,
    ProjectLayoutStates,
    AiUsageLogs,
    AiModelCatalog,
    AiOutputReviews,
    SyncLogs,
    SyncConflicts,
    ProjectCollaborators,
    ProjectComments,
    ActivityEvents,
    SecuritySettings,
    Plugins,
    PluginSettings,
    AnimationTracks,
    AnimationKeyframes,
    AudioAutomationCurves,
    Shots,
    Takes,
    PublishRecords,
    StudioMembers,
    AuditEvents,
    KnowledgeEntities,
    KnowledgeRelations,
    Agents,
    AgentToolCalls,
    CreativeBriefs,
    CreativeIdeas,
    XrSessions,
    SpatialAnchors,
    MetaverseWorlds,
    MetaverseZones,
  ],
  daos: [
    AssetDao,
    CharacterDao,
    CharacterModeDao,
    RelationDao,
    WardrobeDao,
    WeaponDao,
    EnvironmentDao,
    StoryDao,
    TimelineDao,
    ReferenceDao,
    BibleRepository,
    CanonRuleRepository,
    FactionRepository,
    WorldbuildingRepository,
    BibleTimelineRepository,
    CanonConflictRepository,
    CreatureRepository,
    VehicleRepository,
    PropRepository,
    SceneAssetInstanceRepository,
    VfxRepository,
    AudioAssetRepository,
    DialogueRepository,
    AudioTimelineRepository,
    AudioImportRepository,
    ProjectResilienceRepository,
    BackgroundJobDao,
  ],
)
class ProjectDatabase extends _$ProjectDatabase {
  ProjectDatabase(super.executor);

  static const currentSchemaVersion = 58;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(assets);
        await m.createTable(assetTags);
        await m.createTable(characters);
        await m.createTable(characterIdentityProfiles);
        await m.createTable(characterReferences);
        await m.createTable(assetRelations);
      }
      if (from >= 2 && from < 3) {
        await m.addColumn(assetRelations, assetRelations.projectId);
        await m.addColumn(assetRelations, assetRelations.createdAt);
      }
      if (from < 4) {
        await m.createTable(wardrobes);
        await m.createTable(wardrobeComponents);
        await m.createTable(wardrobeColors);
        await m.createTable(wardrobeVariants);
        await m.createTable(wardrobeReferences);
      }
      if (from < 5) {
        await m.createTable(weapons);
        await m.createTable(weaponComponents);
        await m.createTable(weaponMeasurements);
        await m.createTable(weaponColors);
        await m.createTable(weaponEnergyProfiles);
        await m.createTable(weaponVariants);
        await m.createTable(weaponReferences);
        await m.createTable(weaponPreservationProfiles);
      }
      if (from < 6) {
        await m.createTable(characterModes);
        await m.createTable(characterLoadoutEntries);
        await m.createTable(characterModeIdentityOverrides);
        await m.createTable(characterModeReferences);
      }
      if (from >= 6 && from < 7) {
        await m.addColumn(
          characterLoadoutEntries,
          characterLoadoutEntries.quantity,
        );
        await m.addColumn(
          characterIdentityProfiles,
          characterIdentityProfiles.weaponLock,
        );
      }
      if (from >= 7 && from < 8) {
        await m.addColumn(assetRelations, assetRelations.relationOrigin);
      }
      if (from >= 8 && from < 9) {
        await m.addColumn(characterModes, characterModes.accentColor);
        await m.addColumn(characterModes, characterModes.tagsJson);
      }
      if (from < 10) {
        await m.createTable(environments);
        await m.createTable(environmentZones);
        await m.createTable(environmentArchitectures);
        await m.createTable(environmentWeatherProfiles);
        await m.createTable(environmentLightingProfiles);
        await m.createTable(environmentColors);
        await m.createTable(environmentProps);
        await m.createTable(environmentContinuityStates);
        await m.createTable(environmentPhysicsProfiles);
        await m.createTable(environmentReferences);
      }
      if (from < 11) {
        await m.createTable(stories);
        await m.createTable(storyArcs);
        await m.createTable(storyChapters);
        await m.createTable(storyScenes);
        await m.createTable(sceneCharacters);
        await m.createTable(sceneEnvironmentContexts);
        await m.createTable(sceneBeats);
        await m.createTable(sceneContinuityChanges);
        await m.createTable(storyBibleSections);
      }
      if (from < 12) {
        await m.createTable(timelines);
        await m.createTable(timelineTracks);
        await m.createTable(timelineClips);
      }
      if (from < 13) {
        await m.createTable(promptTemplates);
        await m.createTable(aiPromptHistory);
        await m.createTable(promptRevisions);
        await m.createTable(aiGenerations);
      }
      if (from < 14) {
        await m.createTable(aiGenerationJobs);
        await m.createTable(aiGenerationOutputs);
        await m.createTable(aiGenerationInputs);
      }
      if (from < 15) {
        await m.addColumn(assets, assets.favorite);
        await m.addColumn(assets, assets.lastOpenedAt);
        await m.createTable(tags);
        await m.createTable(assetTagLinks);
        await m.createTable(assetCollections);
        await m.createTable(assetCollectionItems);
        await customStatement('''
          INSERT OR IGNORE INTO tags (id, project_id, name)
          SELECT 'legacy_' || asset_id || '_' || lower(trim(tag)), project_id, lower(trim(tag))
          FROM asset_tags
          JOIN assets ON assets.id = asset_tags.asset_id
          WHERE trim(tag) <> ''
        ''');
        await customStatement('''
          INSERT OR IGNORE INTO asset_tag_links (asset_id, tag_id)
          SELECT asset_tags.asset_id, 'legacy_' || asset_tags.asset_id || '_' || lower(trim(asset_tags.tag))
          FROM asset_tags
          WHERE trim(asset_tags.tag) <> ''
        ''');
      }
      if (from < 16) {
        if (from >= 2) {
          await customStatement(
            'ALTER TABLE character_identity_profiles ADD COLUMN accessory_lock BOOLEAN NOT NULL DEFAULT 0',
          );
          await customStatement(
            "ALTER TABLE character_identity_profiles ADD COLUMN notes TEXT NOT NULL DEFAULT ''",
          );
        }
        if (from >= 6) {
          await customStatement(
            'ALTER TABLE character_modes ADD COLUMN reference_set_id TEXT',
          );
        }
        await m.createTable(references);
        await m.createTable(referenceSets);
        await m.createTable(referenceSetItems);
        await m.createTable(referenceVersions);
        await m.createTable(preservationLocks);
        await m.createTable(consistencyRules);
        await m.createTable(consistencyReviews);
        await m.createTable(consistencyReviewItems);
      }
      if (from < 17 && from >= 11) {
        await m.addColumn(storyScenes, storyScenes.referenceSetId);
      }
      if (from < 18) {
        await m.createTable(bibleEntries);
      }
      if (from < 19) {
        await m.createTable(canonRules);
        await m.createTable(canonRuleConditions);
      }
      if (from < 20) {
        await m.createTable(factions);
      }
      if (from < 21) {
        await m.createTable(species);
        await m.createTable(technologies);
        await m.createTable(powerSystems);
        await m.createTable(powerAbilities);
      }
      if (from < 22) {
        await m.createTable(terminologyEntries);
        await m.createTable(timelineEras);
        await m.createTable(historicalEvents);
        await m.createTable(historicalEventParticipants);
      }
      if (from < 23) {
        await m.createTable(factionUnits);
      }
      if (from < 24) {
        await m.createTable(canonConflicts);
        await m.createTable(canonRuleExceptions);
      }
      if (from < 25) {
        await m.createTable(creatures);
        await m.createTable(creaturePhysicalProfiles);
        await m.createTable(creatureAbilities);
        await m.createTable(creatureModes);
      }
      if (from < 26) {
        await m.createTable(vehicles);
        await m.createTable(vehicleSpecifications);
        await m.createTable(vehicleComponents);
        await m.createTable(vehicleWeaponMounts);
        await m.createTable(vehicleVariants);
      }
      if (from < 27) {
        await m.createTable(props);
        await m.createTable(propSpecifications);
        await m.createTable(propStates);
      }
      if (from < 28) {
        await m.createTable(sceneAssetInstances);
        await m.createTable(sceneInstanceTransforms);
        await m.createTable(sceneInstanceProperties);
        await m.createTable(sceneContinuitySnapshots);
      }
      if (from < 29) {
        await m.createTable(vfxAssets);
        await m.createTable(vfxBehaviorProfiles);
        await m.createTable(vfxStates);
        await m.createTable(vfxTimelineClips);
        await m.createTable(vfxKeyframes);
      }
      if (from < 30) {
        await m.createTable(audioFiles);
        await m.createTable(soundEffects);
        await m.createTable(soundEffectVariations);
        await m.createTable(ambienceAssets);
        await m.createTable(ambienceLayers);
        await m.createTable(ambienceVariants);
        await m.createTable(musicCues);
        await m.createTable(musicSections);
      }
      if (from < 31) {
        await m.createTable(voiceProfiles);
        await m.createTable(voiceReferences);
        await m.createTable(dialogueLines);
        await m.createTable(dialogueTakes);
      }
      if (from < 32) {
        await m.createTable(audioTimelineClips);
        await m.createTable(audioAutomationKeyframes);
      }
      if (from < 33) {
        await m.createTable(audioWaveformCaches);
      }
      if (from < 34) {
        await m.createTable(externalFiles);
        await m.createTable(projectBackups);
        await m.createTable(cacheEntries);
        await m.createTable(trashEntries);
        await m.createTable(projectMigrationHistory);
      }
      if (from < 35) {
        await m.createTable(commandHistoryEntries);
      }
      if (from < 36) {
        await m.createTable(backgroundJobs);
      }
      if (from < 37) {
        await _createIndexes();
      }
      if (from < 38) {
        await m.createTable(jobDependencies);
      }
      if (from < 39) {
        await m.createTable(layoutPresets);
        await m.createTable(projectLayoutStates);
      }
      if (from < 40) {
        await m.createTable(aiUsageLogs);
        await m.createTable(aiModelCatalog);
        await m.createTable(aiOutputReviews);
      }
      if (from < 41) {
        await m.createTable(syncLogs);
        await m.createTable(syncConflicts);
        await m.createTable(projectCollaborators);
        await m.createTable(projectComments);
        await m.createTable(activityEvents);
      }
      if (from < 42) {
        await m.createTable(securitySettings);
      }
      if (from < 43) {
        await m.createTable(plugins);
        await m.createTable(pluginSettings);
      }
      if (from < 44) {
        await m.createTable(animationTracks);
        await m.createTable(animationKeyframes);
      }
      if (from < 45) {
        await m.createTable(audioAutomationCurves);
      }
      if (from < 46) {
        await m.createTable(shots);
        await m.createTable(takes);
      }
      if (from < 47) {
        await m.createTable(publishRecords);
      }
      if (from < 48) {
        await m.createTable(studioMembers);
        await m.createTable(auditEvents);
      }
      if (from < 49) {
        await m.createTable(knowledgeEntities);
        await m.createTable(knowledgeRelations);
      }
      if (from < 50) {
        await m.createTable(agents);
        await m.createTable(agentToolCalls);
      }
      if (from < 51) {
        await m.createTable(creativeBriefs);
        await m.createTable(creativeIdeas);
      }
      if (from < 52) {
        await m.createTable(xrSessions);
        await m.createTable(spatialAnchors);
      }
      if (from < 53) {
        await m.createTable(metaverseWorlds);
        await m.createTable(metaverseZones);
      }
      if (from < 54) {
        await m.createTable(creatureEcologyStates);
      }
      if (from < 55) {
        await m.createTable(novelCharacterLinks);
      }
      if (from < 56) {
        await m.createTable(workflowDefinitions);
        await m.createTable(workflowRunRecords);
      }
      if (from < 57) {
        await m.createTable(sceneDraftSnapshots);
      }
      if (from < 58) {
        await m.addColumn(characters, characters.voice);
      }
    },
  );

  Future<void> _createIndexes() async {
    const indexStatements = [
      'CREATE INDEX IF NOT EXISTS idx_assets_project_id ON assets (project_id)',
      'CREATE INDEX IF NOT EXISTS idx_assets_type ON assets (type)',
      'CREATE INDEX IF NOT EXISTS idx_assets_name ON assets (name)',
      'CREATE INDEX IF NOT EXISTS idx_assets_updated_at ON assets (updated_at)',
      'CREATE INDEX IF NOT EXISTS idx_assets_project_type_updated '
          'ON assets (project_id, type, updated_at)',
      'CREATE INDEX IF NOT EXISTS idx_asset_tags_asset_id ON asset_tags (asset_id)',
      'CREATE INDEX IF NOT EXISTS idx_asset_tags_tag ON asset_tags (tag)',
      'CREATE INDEX IF NOT EXISTS idx_asset_tag_links_asset_id '
          'ON asset_tag_links (asset_id)',
      'CREATE INDEX IF NOT EXISTS idx_asset_tag_links_tag_id '
          'ON asset_tag_links (tag_id)',
      'CREATE INDEX IF NOT EXISTS idx_asset_relations_source '
          'ON asset_relations (source_asset_id)',
      'CREATE INDEX IF NOT EXISTS idx_asset_relations_target '
          'ON asset_relations (target_asset_id)',
      'CREATE INDEX IF NOT EXISTS idx_scene_characters_scene_id '
          'ON scene_characters (scene_id)',
      'CREATE INDEX IF NOT EXISTS idx_timeline_clips_track_id '
          'ON timeline_clips (track_id)',
      'CREATE INDEX IF NOT EXISTS idx_timeline_clips_start_seconds '
          'ON timeline_clips (start_seconds)',
    ];
    for (final statement in indexStatements) {
      await customStatement(statement);
    }
  }

  Future<void> initialize() async {
    await customStatement(
      'INSERT INTO project_metadata (key, value) VALUES (?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      ['schemaVersion', schemaVersion.toString()],
    );
  }
}
