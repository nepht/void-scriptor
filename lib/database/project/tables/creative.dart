import 'package:drift/drift.dart';

/// Creative briefs (Step 40.13).
class CreativeBriefs extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get genre => text()();
  TextColumn get tone => text()();
  TextColumn get goalsJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Creative ideas (Step 40.14).
class CreativeIdeas extends Table {
  TextColumn get id => text()();
  TextColumn get briefId => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}
