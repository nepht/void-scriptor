import 'package:drift/drift.dart';

class AudioTimelineClips extends Table {
  TextColumn get id => text()();
  TextColumn get timelineId => text()();
  TextColumn get trackType => text()();
  TextColumn get audioFileId => text()();
  RealColumn get startSeconds => real()();
  RealColumn get durationSeconds => real()();
  RealColumn get fadeInSeconds => real().withDefault(const Constant(0))();
  RealColumn get fadeOutSeconds => real().withDefault(const Constant(0))();
  RealColumn get gainDb => real().withDefault(const Constant(0))();
  RealColumn get pan => real().withDefault(const Constant(0))();
  TextColumn get intent => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AudioAutomationKeyframes extends Table {
  TextColumn get id => text()();
  TextColumn get clipId => text()();
  RealColumn get timeSeconds => real()();
  TextColumn get parameter => text()();
  RealColumn get value => real()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
