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

class StoryRepositoryImpl {
  StoryRepositoryImpl({required this.database, required this.projectId});
  final ProjectDatabase database;
  final String projectId;

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
}
