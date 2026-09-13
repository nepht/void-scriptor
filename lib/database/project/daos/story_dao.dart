import 'package:drift/drift.dart';
import '../project_database.dart';
import '../tables/stories.dart';
import '../tables/story_arcs.dart';
import '../tables/story_chapters.dart';
import '../tables/story_scenes.dart';
import '../tables/scene_characters.dart';
import '../tables/scene_environment_contexts.dart';
import '../tables/scene_beats.dart';
import '../tables/scene_draft_snapshots.dart';
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
    SceneDraftSnapshots,
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
  Future<List<StoryScene>> getScenesByChapter(String chapterId) =>
      (select(storyScenes)
            ..where((t) => t.chapterId.equals(chapterId))
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

  /// Urutan kronologis snapshot scene. vs-hunt-20260912-autosave BUG-9
  /// (Low): tie-breaker rowid — clock mundur/duplikat timestamp tidak lagi
  /// membuat urutan prune nondeterministik (rowid = urutan insert monotonik
  /// pada tabel rowid SQLite).
  static const _rowId = CustomExpression<int>('rowid');

  Future<List<SceneDraftSnapshot>> getSceneDraftSnapshots(String sceneId) =>
      (select(sceneDraftSnapshots)
            ..where((t) => t.sceneId.equals(sceneId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.createdAt),
              (t) => OrderingTerm(expression: _rowId),
            ]))
          .get();

  Future<void> insertSceneDraftSnapshot(SceneDraftSnapshotsCompanion entry) =>
      into(sceneDraftSnapshots).insert(entry);

  Future<int> deleteSceneDraftSnapshotsBefore(
    String sceneId,
    DateTime cutoff,
  ) =>
      (delete(sceneDraftSnapshots)..where(
            (t) =>
                t.sceneId.equals(sceneId) &
                t.createdAt.isSmallerThanValue(cutoff),
          ))
          .go();

  Future<void> deleteSceneDraftSnapshotsForScene(String sceneId) => (delete(
    sceneDraftSnapshots,
  )..where((t) => t.sceneId.equals(sceneId))).go();

  Future<void> deleteSceneDraftSnapshotByIds(List<String> ids) =>
      (delete(sceneDraftSnapshots)..where((t) => t.id.isIn(ids))).go();
}
