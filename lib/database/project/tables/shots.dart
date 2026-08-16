import 'package:drift/drift.dart';

/// Shots (Step 35.13).
class Shots extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get startSeconds => real()();
  RealColumn get durationSeconds => real()();
  TextColumn get cameraId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Takes (Step 35.13).
class Takes extends Table {
  TextColumn get id => text()();
  TextColumn get shotId => text()();
  IntColumn get takeNumber => integer()();
  TextColumn get state => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}
