import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';
import '../domain/story_model.dart';

class StoryHierarchy {
  const StoryHierarchy({
    required this.story,
    required this.arcs,
    required this.chapters,
    required this.scenes,
  });
  final StoryModel story;
  final List<StoryArcNode> arcs;
  final List<StoryChapterNode> chapters;
  final List<StorySceneNode> scenes;
}

class StoryArcNode {
  const StoryArcNode(this.id, this.title, this.chapters);
  final String id;
  final String title;
  final List<StoryChapterNode> chapters;
}

class StoryChapterNode {
  const StoryChapterNode(this.id, this.title, this.scenes);
  final String id;
  final String title;
  final List<StorySceneNode> scenes;
}

class StorySceneNode {
  const StorySceneNode(
    this.id,
    this.title,
    this.characters,
    this.environment,
    this.beats,
  );
  final String id;
  final String title;
  final List<SceneCharacter> characters;
  final SceneEnvironmentContext? environment;
  final List<SceneBeat> beats;
}

class NovelSearchResult {
  const NovelSearchResult({
    required this.sceneId,
    required this.sceneTitle,
    required this.chapterTitle,
    required this.matchCount,
  });
  final String sceneId;
  final String sceneTitle;
  final String chapterTitle;
  final int matchCount;
}

class StoryRepositoryImpl {
  StoryRepositoryImpl({required this.database, required this.projectId});
  final ProjectDatabase database;
  final String projectId;

  Future<void> saveSceneDraft(String sceneId, String content) async {
    final existing =
        await (database.select(database.sceneBeats)..where(
              (row) =>
                  row.sceneId.equals(sceneId) & row.beatType.equals('draft'),
            ))
            .getSingleOrNull();
    if (existing == null) {
      await database
          .into(database.sceneBeats)
          .insert(
            SceneBeatsCompanion.insert(
              id: '${sceneId}_draft',
              sceneId: sceneId,
              beatType: const Value('draft'),
              content: content,
            ),
          );
    } else {
      await (database.update(database.sceneBeats)
            ..where((row) => row.id.equals(existing.id)))
          .write(SceneBeatsCompanion(content: Value(content)));
    }
  }

  Future<String?> getSceneDraft(String sceneId) async {
    final draft =
        await (database.select(database.sceneBeats)..where(
              (row) =>
                  row.sceneId.equals(sceneId) & row.beatType.equals('draft'),
            ))
            .getSingleOrNull();
    return draft?.content;
  }

  Future<StorySceneNode?> getScene(String sceneId) async {
    final scene = await database.storyDao.getScene(sceneId);
    if (scene == null) return null;
    return StorySceneNode(
      scene.id,
      scene.title,
      await database.storyDao.getSceneCharacters(scene.id),
      await database.storyDao.getSceneEnvironment(scene.id),
      await database.storyDao.getSceneBeats(scene.id),
    );
  }

  Future<StoryHierarchy> getStoryHierarchy(String storyId) async {
    final story = await database.storyDao.getStory(storyId);
    if (story == null || story.projectId != projectId) {
      throw StateError('Story not found');
    }
    final arcs = await database.storyDao.getArcs(storyId);
    final chapters = await database.storyDao.getChapters(storyId);
    final scenes = await database.storyDao.getScenes(storyId);
    final sceneNodes = <StorySceneNode>[];
    for (final scene in scenes) {
      sceneNodes.add(
        StorySceneNode(
          scene.id,
          scene.title,
          await database.storyDao.getSceneCharacters(scene.id),
          await database.storyDao.getSceneEnvironment(scene.id),
          await database.storyDao.getSceneBeats(scene.id),
        ),
      );
    }
    final chapterNodes = chapters
        .map(
          (chapter) => StoryChapterNode(
            chapter.id,
            chapter.title,
            sceneNodes
                .where(
                  (s) =>
                      scenes.firstWhere((x) => x.id == s.id).chapterId ==
                      chapter.id,
                )
                .toList(),
          ),
        )
        .toList();
    final arcNodes = arcs
        .map(
          (arc) => StoryArcNode(
            arc.id,
            arc.title,
            chapterNodes
                .where(
                  (c) =>
                      chapters.firstWhere((x) => x.id == c.id).arcId == arc.id,
                )
                .toList(),
          ),
        )
        .toList();
    return StoryHierarchy(
      story: StoryModel(
        assetId: story.assetId,
        projectId: story.projectId,
        title: story.title,
        synopsis: story.synopsis,
        genre: story.genre,
        status: story.status,
        notes: story.notes,
      ),
      arcs: arcNodes,
      chapters: chapterNodes,
      scenes: sceneNodes,
    );
  }

  /// Pencarian novel lintas scene untuk langkah 145.24: mencocokkan query
  /// (case-insensitive, di-trim) terhadap judul scene, judul bab, dan isi
  /// draft/beat scene. Hasil unik per scene, tersegmen per chapter, terurut
  /// mengikuti chapter lalu scene (sortOrder). Query kosong tidak mencari.
  Future<List<NovelSearchResult>> searchNovel(String query) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const <NovelSearchResult>[];

    final storyIds = await (database.select(
      database.stories,
    )..where((t) => t.projectId.equals(projectId))).get();
    if (storyIds.isEmpty) return const <NovelSearchResult>[];

    final matches = <String, NovelSearchResult>{};
    for (final story in storyIds) {
      final chapters = await database.storyDao.getChapters(story.assetId);
      for (final chapter in chapters) {
        final scenes = await database.storyDao.getScenesByChapter(chapter.id);
        for (final scene in scenes) {
          var count = 0;
          if (scene.title.toLowerCase().contains(needle)) count++;
          if (chapter.title.toLowerCase().contains(needle)) count++;
          final beats = await database.storyDao.getSceneBeats(scene.id);
          for (final beat in beats) {
            if (beat.content.toLowerCase().contains(needle)) count++;
          }
          if (count > 0) {
            final existing = matches[scene.id];
            matches[scene.id] = NovelSearchResult(
              sceneId: scene.id,
              sceneTitle: scene.title,
              chapterTitle: chapter.title,
              matchCount: existing == null
                  ? count
                  : existing.matchCount + count,
            );
          }
        }
      }
    }
    return matches.values.toList(growable: false);
  }
}
