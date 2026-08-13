// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bible_timeline_repository.dart';

// ignore_for_file: type=lint
mixin _$BibleTimelineRepositoryMixin on DatabaseAccessor<ProjectDatabase> {
  $TerminologyEntriesTable get terminologyEntries =>
      attachedDatabase.terminologyEntries;
  $TimelineErasTable get timelineEras => attachedDatabase.timelineEras;
  $HistoricalEventsTable get historicalEvents =>
      attachedDatabase.historicalEvents;
  $HistoricalEventParticipantsTable get historicalEventParticipants =>
      attachedDatabase.historicalEventParticipants;
  BibleTimelineRepositoryManager get managers =>
      BibleTimelineRepositoryManager(this);
}

class BibleTimelineRepositoryManager {
  final _$BibleTimelineRepositoryMixin _db;
  BibleTimelineRepositoryManager(this._db);
  $$TerminologyEntriesTableTableManager get terminologyEntries =>
      $$TerminologyEntriesTableTableManager(
        _db.attachedDatabase,
        _db.terminologyEntries,
      );
  $$TimelineErasTableTableManager get timelineEras =>
      $$TimelineErasTableTableManager(_db.attachedDatabase, _db.timelineEras);
  $$HistoricalEventsTableTableManager get historicalEvents =>
      $$HistoricalEventsTableTableManager(
        _db.attachedDatabase,
        _db.historicalEvents,
      );
  $$HistoricalEventParticipantsTableTableManager
  get historicalEventParticipants =>
      $$HistoricalEventParticipantsTableTableManager(
        _db.attachedDatabase,
        _db.historicalEventParticipants,
      );
}
