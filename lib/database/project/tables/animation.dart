import 'package:drift/drift.dart';

/// Animation tracks (Step 33.13).
class AnimationTracks extends Table {
  TextColumn get id => text()();
  TextColumn get clipId => text()();
  TextColumn get name => text()();
  TextColumn get targetProperty => text()();
  TextColumn get interpolation => text()();
  RealColumn get durationSeconds => real()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Keyframes for animation tracks (Step 33.13).
class AnimationKeyframes extends Table {
  TextColumn get id => text()();
  TextColumn get trackId => text()();
  RealColumn get timeSeconds => real()();
  RealColumn get value => real()();

  @override
  Set<Column> get primaryKey => {id};
}
