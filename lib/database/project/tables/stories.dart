import 'package:drift/drift.dart';

class Stories extends Table {
  TextColumn get assetId => text()();
  TextColumn get projectId => text()();
  TextColumn get title => text()();
  TextColumn get synopsis => text().withDefault(const Constant(''))();
  TextColumn get genre => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  @override
  Set<Column<Object>> get primaryKey => {assetId};
}
