import 'package:drift/drift.dart';

class EnvironmentWeatherProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get environmentId => text()();
  TextColumn get name => text()();
  TextColumn get weatherPreset => text()();
  RealColumn get intensity => real().withDefault(const Constant(1.0))();
  RealColumn get windStrength => real().withDefault(const Constant(0.0))();
  RealColumn get visibility => real().withDefault(const Constant(1.0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
