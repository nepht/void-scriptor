import 'package:drift/drift.dart';

class TerminologyEntries extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get term => text()();
  TextColumn get definition => text()();
  TextColumn get category => text().withDefault(const Constant('general'))();
  TextColumn get alternateTerms => text().withDefault(const Constant(''))();
  BoolColumn get caseSensitive =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TimelineEras extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get orderIndex => integer()();
  TextColumn get startLabel => text().nullable()();
  TextColumn get endLabel => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class HistoricalEvents extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get eraId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get orderIndex => integer()();
  TextColumn get canonStatus => text().withDefault(const Constant('canon'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class HistoricalEventParticipants extends Table {
  TextColumn get id => text()();
  TextColumn get eventId => text()();
  TextColumn get assetId => text()();
  TextColumn get role => text().withDefault(const Constant('participant'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
