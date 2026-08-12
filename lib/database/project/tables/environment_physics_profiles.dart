import 'package:drift/drift.dart';

class EnvironmentPhysicsProfiles extends Table {
  TextColumn get environmentId => text()();
  RealColumn get gravityMultiplier => real().withDefault(const Constant(1.0))();
  BoolColumn get floatingObjects =>
      boolean().withDefault(const Constant(false))();
  TextColumn get dimensionalDistortion =>
      text().withDefault(const Constant('none'))();
  TextColumn get portalBehavior =>
      text().withDefault(const Constant('normal'))();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {environmentId};
}
