import 'package:drift/drift.dart';

class CanonConflicts extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get ruleId => text()();
  TextColumn get targetId => text()();
  TextColumn get message => text()();
  TextColumn get severity => text()();
  BoolColumn get resolved => boolean().withDefault(const Constant(false))();
  TextColumn get resolutionNote => text().withDefault(const Constant(''))();
  DateTimeColumn get detectedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CanonRuleExceptions extends Table {
  TextColumn get id => text()();
  TextColumn get ruleId => text()();
  TextColumn get targetId => text()();
  TextColumn get reason => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
