// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_dao.dart';

// ignore_for_file: type=lint
mixin _$TimelineDaoMixin on DatabaseAccessor<ProjectDatabase> {
  $TimelinesTable get timelines => attachedDatabase.timelines;
  $TimelineTracksTable get timelineTracks => attachedDatabase.timelineTracks;
  $TimelineClipsTable get timelineClips => attachedDatabase.timelineClips;
  TimelineDaoManager get managers => TimelineDaoManager(this);
}

class TimelineDaoManager {
  final _$TimelineDaoMixin _db;
  TimelineDaoManager(this._db);
  $$TimelinesTableTableManager get timelines =>
      $$TimelinesTableTableManager(_db.attachedDatabase, _db.timelines);
  $$TimelineTracksTableTableManager get timelineTracks =>
      $$TimelineTracksTableTableManager(
        _db.attachedDatabase,
        _db.timelineTracks,
      );
  $$TimelineClipsTableTableManager get timelineClips =>
      $$TimelineClipsTableTableManager(_db.attachedDatabase, _db.timelineClips);
}
