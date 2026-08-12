import 'package:drift/drift.dart';

class EnvironmentArchitectures extends Table {
  TextColumn get environmentId => text()();
  TextColumn get style => text().withDefault(const Constant(''))();
  TextColumn get structure => text().withDefault(const Constant(''))();
  TextColumn get materials => text().withDefault(const Constant(''))();
  TextColumn get scale => text().withDefault(const Constant(''))();
  TextColumn get condition => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {environmentId};
}
