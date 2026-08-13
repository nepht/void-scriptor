import 'package:drift/drift.dart';
import '../project_database.dart';
import '../tables/stories.dart';
import '../tables/story_arcs.dart';
import '../tables/story_chapters.dart';
import '../tables/story_scenes.dart';
import '../tables/scene_characters.dart';
import '../tables/scene_environment_contexts.dart';
import '../tables/scene_beats.dart';
import '../tables/scene_continuity_changes.dart';
import '../tables/story_bible_sections.dart';

part 'story_dao.g.dart';

@DriftAccessor(
  tables: [
    Stories,
    StoryArcs,
    StoryChapters,
    StoryScenes,
    SceneCharacters,
    SceneEnvironmentContexts,
    SceneBeats,
    SceneContinuityChanges,
    StoryBibleSections,
  ],
)
class StoryDao extends DatabaseAccessor<ProjectDatabase> with _$StoryDaoMixin {
  StoryDao(super.db);
  Future<Story?> getStory(String id) =>
      (select(stories)..where((t) => t.assetId.equals(id))).getSingleOrNull();
  Future<List<StoryArc>> getArcs(String storyId) =>
      (select(storyArcs)
            ..where((t) => t.storyId.equals(storyId))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();
  Future<List<StoryChapter>> getChapters(String storyId) =>
      (select(storyChapters)
            ..where((t) => t.storyId.equals(storyId))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();
  Future<List<StoryScene>> getScenes(String storyId) =>
      (select(storyScenes)
            ..where((t) => t.storyId.equals(storyId))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();
  Future<StoryScene?> getScene(String sceneId) => (select(
    storyScenes,
  )..where((t) => t.id.equals(sceneId))).getSingleOrNull();
  Future<List<SceneCharacter>> getSceneCharacters(String sceneId) =>
      (select(sceneCharacters)
            ..where((t) => t.sceneId.equals(sceneId))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();
  Future<SceneEnvironmentContext?> getSceneEnvironment(String sceneId) =>
      (select(
        sceneEnvironmentContexts,
      )..where((t) => t.sceneId.equals(sceneId))).getSingleOrNull();
  Future<List<SceneBeat>> getSceneBeats(String sceneId) =>
      (select(sceneBeats)
            ..where((t) => t.sceneId.equals(sceneId))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();
}
