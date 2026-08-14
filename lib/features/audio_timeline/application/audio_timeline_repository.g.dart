// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_timeline_repository.dart';

// ignore_for_file: type=lint
mixin _$AudioTimelineRepositoryMixin on DatabaseAccessor<ProjectDatabase> {
  $AudioTimelineClipsTable get audioTimelineClips =>
      attachedDatabase.audioTimelineClips;
  $AudioAutomationKeyframesTable get audioAutomationKeyframes =>
      attachedDatabase.audioAutomationKeyframes;
  AudioTimelineRepositoryManager get managers =>
      AudioTimelineRepositoryManager(this);
}

class AudioTimelineRepositoryManager {
  final _$AudioTimelineRepositoryMixin _db;
  AudioTimelineRepositoryManager(this._db);
  $$AudioTimelineClipsTableTableManager get audioTimelineClips =>
      $$AudioTimelineClipsTableTableManager(
        _db.attachedDatabase,
        _db.audioTimelineClips,
      );
  $$AudioAutomationKeyframesTableTableManager get audioAutomationKeyframes =>
      $$AudioAutomationKeyframesTableTableManager(
        _db.attachedDatabase,
        _db.audioAutomationKeyframes,
      );
}
