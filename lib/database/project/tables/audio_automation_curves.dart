import 'package:drift/drift.dart';

/// Audio automation curves (Step 34.13).
class AudioAutomationCurves extends Table {
  TextColumn get id => text()();
  TextColumn get clipId => text()();
  TextColumn get parameter => text()();
  TextColumn get interpolation => text()();
  RealColumn get timeSeconds => real()();
  RealColumn get value => real()();

  @override
  Set<Column> get primaryKey => {id};
}
