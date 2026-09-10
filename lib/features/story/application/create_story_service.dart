import 'package:drift/drift.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

import '../../../core/persistence/project_paths.dart';
import '../../../database/project/project_database.dart';

class CreateStoryService {
  CreateStoryService({required this.database, required this.paths});
  final ProjectDatabase database;
  final ProjectPaths paths;

  Future<String> createStory({
    required String projectId,
    required String title,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final directory = await paths.project(projectId);
    final storyDirectory = DirectoryPath(
      '${directory.path}/assets/stories/$id',
    );
    try {
      await database.transaction(() async {
        await database
            .into(database.assets)
            .insert(
              AssetsCompanion.insert(
                id: id,
                projectId: projectId,
                name: title,
                type: 'story',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await database
            .into(database.stories)
            .insert(
              StoriesCompanion.insert(
                assetId: id,
                projectId: projectId,
                title: title,
              ),
            );
      });
      for (final child in [
        'references',
        'scene_art',
        'storyboards',
        'exports',
        'attachments',
      ]) {
        await storyDirectory.child(child).create(recursive: true);
      }
      return id;
    } catch (_) {
      await storyDirectory.deleteIfExists();
      rethrow;
    }
  }

  /// Creates a story with its seeded Chapter 1 / Scene 1 atomically.
  ///
  /// hunt-run171 BUG-9 (Referee REAL BUG Medium): both production call sites
  /// chained createStory → createChapter → createScene with three separate
  /// autocommit writes and no rollback, so a failure after createStory left
  /// an orphaned story row (retry duplicates the novel). This method groups
  /// the three inserts in ONE database transaction — any step failing rolls
  /// back every row — and removes the story folder createStory materialized
  /// when the transaction fails. Caller surfaces still show their existing
  /// failure snackbar.
  Future<String> createNovelWithFirstChapter({
    required String projectId,
    required String title,
  }) async {
    final directory = await paths.project(projectId);
    final storyDirectory = DirectoryPath('${directory.path}/assets/stories');
    var storyId = '';
    try {
      await database.transaction(() async {
        storyId = await createStory(projectId: projectId, title: title);
        final chapterId = await createChapter(
          storyId: storyId,
          title: 'Chapter 1',
          chapterNumber: 1,
        );
        await createScene(
          storyId: storyId,
          chapterId: chapterId,
          title: 'Scene 1',
          sceneNumber: 1,
        );
      });
      return storyId;
    } catch (_) {
      // createStory already deletes its own folder when ITS step fails; when
      // a later step fails the folder it made would linger, so remove it.
      final created = DirectoryPath('${storyDirectory.path}/$storyId');
      try {
        if (storyId.isNotEmpty) await created.deleteIfExists();
      } catch (_) {
        // Best-effort cleanup; the original failure must still propagate.
      }
      rethrow;
    }
  }

  Future<String> createArc({
    required String storyId,
    required String title,
  }) async {
    final id = const Uuid().v4();
    await database
        .into(database.storyArcs)
        .insert(
          StoryArcsCompanion.insert(id: id, storyId: storyId, title: title),
        );
    return id;
  }

  Future<String> createChapter({
    required String storyId,
    String? arcId,
    required String title,
    required int chapterNumber,
  }) async {
    final id = const Uuid().v4();
    await database
        .into(database.storyChapters)
        .insert(
          StoryChaptersCompanion.insert(
            id: id,
            storyId: storyId,
            arcId: Value(arcId),
            title: title,
            chapterNumber: chapterNumber,
          ),
        );
    return id;
  }

  Future<String> createScene({
    required String storyId,
    required String chapterId,
    required String title,
    required int sceneNumber,
    double? estimatedDurationSeconds,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    await database
        .into(database.storyScenes)
        .insert(
          StoryScenesCompanion.insert(
            id: id,
            storyId: storyId,
            chapterId: chapterId,
            title: title,
            sceneNumber: sceneNumber,
            estimatedDurationSeconds: Value(estimatedDurationSeconds),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> addCharacter({
    required String sceneId,
    required String characterId,
    String? modeId,
    String role = 'participant',
  }) => database
      .into(database.sceneCharacters)
      .insert(
        SceneCharactersCompanion.insert(
          id: const Uuid().v4(),
          sceneId: sceneId,
          characterId: characterId,
          modeId: Value(modeId),
          role: Value(role),
        ),
      );

  Future<void> setEnvironmentContext({
    required String sceneId,
    required String environmentId,
    String? zoneId,
    String? weatherProfileId,
    String? lightingProfileId,
    String? continuityStateId,
    String? timePreset,
  }) => database
      .into(database.sceneEnvironmentContexts)
      .insertOnConflictUpdate(
        SceneEnvironmentContextsCompanion.insert(
          sceneId: sceneId,
          environmentId: environmentId,
          zoneId: Value(zoneId),
          weatherProfileId: Value(weatherProfileId),
          lightingProfileId: Value(lightingProfileId),
          continuityStateId: Value(continuityStateId),
          timePreset: Value(timePreset),
        ),
      );

  Future<String> addBeat({
    required String sceneId,
    required String content,
    String beatType = 'action',
    double? startSecond,
    double? durationSeconds,
  }) async {
    final id = const Uuid().v4();
    await database
        .into(database.sceneBeats)
        .insert(
          SceneBeatsCompanion.insert(
            id: id,
            sceneId: sceneId,
            beatType: Value(beatType),
            content: content,
            startSecond: Value(startSecond),
            durationSeconds: Value(durationSeconds),
          ),
        );
    return id;
  }

  Future<void> reorderBeats({
    required String sceneId,
    required List<String> orderedIds,
  }) async {
    await database.transaction(() async {
      for (var index = 0; index < orderedIds.length; index++) {
        await (database.update(database.sceneBeats)
              ..where((row) => row.id.equals(orderedIds[index])))
            .write(SceneBeatsCompanion(sortOrder: Value(index)));
      }
    });
  }

  Future<void> deleteBeat(String id) => (database.delete(
    database.sceneBeats,
  )..where((row) => row.id.equals(id))).go();
}

class DirectoryPath {
  DirectoryPath(this.path);
  final String path;
  Directory get directory => Directory(path);
  DirectoryPath child(String name) => DirectoryPath('$path/$name');
  Future<void> create({bool recursive = false}) =>
      directory.create(recursive: recursive);
  Future<void> deleteIfExists() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
