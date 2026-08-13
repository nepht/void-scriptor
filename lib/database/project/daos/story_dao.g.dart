// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_dao.dart';

// ignore_for_file: type=lint
mixin _$StoryDaoMixin on DatabaseAccessor<ProjectDatabase> {
  $StoriesTable get stories => attachedDatabase.stories;
  $StoryArcsTable get storyArcs => attachedDatabase.storyArcs;
  $StoryChaptersTable get storyChapters => attachedDatabase.storyChapters;
  $StoryScenesTable get storyScenes => attachedDatabase.storyScenes;
  $SceneCharactersTable get sceneCharacters => attachedDatabase.sceneCharacters;
  $SceneEnvironmentContextsTable get sceneEnvironmentContexts =>
      attachedDatabase.sceneEnvironmentContexts;
  $SceneBeatsTable get sceneBeats => attachedDatabase.sceneBeats;
  $SceneContinuityChangesTable get sceneContinuityChanges =>
      attachedDatabase.sceneContinuityChanges;
  $StoryBibleSectionsTable get storyBibleSections =>
      attachedDatabase.storyBibleSections;
  StoryDaoManager get managers => StoryDaoManager(this);
}

class StoryDaoManager {
  final _$StoryDaoMixin _db;
  StoryDaoManager(this._db);
  $$StoriesTableTableManager get stories =>
      $$StoriesTableTableManager(_db.attachedDatabase, _db.stories);
  $$StoryArcsTableTableManager get storyArcs =>
      $$StoryArcsTableTableManager(_db.attachedDatabase, _db.storyArcs);
  $$StoryChaptersTableTableManager get storyChapters =>
      $$StoryChaptersTableTableManager(_db.attachedDatabase, _db.storyChapters);
  $$StoryScenesTableTableManager get storyScenes =>
      $$StoryScenesTableTableManager(_db.attachedDatabase, _db.storyScenes);
  $$SceneCharactersTableTableManager get sceneCharacters =>
      $$SceneCharactersTableTableManager(
        _db.attachedDatabase,
        _db.sceneCharacters,
      );
  $$SceneEnvironmentContextsTableTableManager get sceneEnvironmentContexts =>
      $$SceneEnvironmentContextsTableTableManager(
        _db.attachedDatabase,
        _db.sceneEnvironmentContexts,
      );
  $$SceneBeatsTableTableManager get sceneBeats =>
      $$SceneBeatsTableTableManager(_db.attachedDatabase, _db.sceneBeats);
  $$SceneContinuityChangesTableTableManager get sceneContinuityChanges =>
      $$SceneContinuityChangesTableTableManager(
        _db.attachedDatabase,
        _db.sceneContinuityChanges,
      );
  $$StoryBibleSectionsTableTableManager get storyBibleSections =>
      $$StoryBibleSectionsTableTableManager(
        _db.attachedDatabase,
        _db.storyBibleSections,
      );
}
