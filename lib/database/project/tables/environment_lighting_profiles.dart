import 'package:drift/drift.dart';

class EnvironmentLightingProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get environmentId => text()();
  TextColumn get name => text()();
  TextColumn get timePreset => text()();
  TextColumn get keyLight => text().withDefault(const Constant(''))();
  TextColumn get fillLight => text().withDefault(const Constant(''))();
  TextColumn get rimLight => text().withDefault(const Constant(''))();
  TextColumn get environmentLight => text().withDefault(const Constant(''))();
  TextColumn get practicalLights => text().withDefault(const Constant(''))();
  RealColumn get fogDensity => real().withDefault(const Constant(0.0))();
  RealColumn get bloomIntensity => real().withDefault(const Constant(0.0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
