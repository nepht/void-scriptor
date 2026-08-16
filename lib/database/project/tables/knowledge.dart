import 'package:drift/drift.dart';

/// Knowledge entities (Step 38.13).
class KnowledgeEntities extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get factsJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Knowledge relations (Step 38.14).
class KnowledgeRelations extends Table {
  TextColumn get id => text()();
  TextColumn get sourceId => text()();
  TextColumn get targetId => text()();
  TextColumn get kind => text()();

  @override
  Set<Column> get primaryKey => {id};
}
