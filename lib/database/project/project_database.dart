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
import 'tables/characters.dart';
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
import 'daos/wardrobe_dao.dart';
import 'daos/weapon_dao.dart';
import 'daos/environment_dao.dart';
import 'daos/story_dao.dart';

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
    SceneContinuityChanges,
    StoryBibleSections,
    Timelines,
    TimelineTracks,
    TimelineClips,
    PromptTemplates,
    AiPromptHistory,
    PromptRevisions,
    AiGenerations,
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
  ],
)
class ProjectDatabase extends _$ProjectDatabase {
  ProjectDatabase(super.executor);

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
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
    },
  );

  Future<void> initialize() async {
    await customStatement(
      'INSERT OR IGNORE INTO project_metadata (key, value) VALUES (?, ?)',
      ['schemaVersion', schemaVersion.toString()],
    );
  }
}
