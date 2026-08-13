import 'package:drift/drift.dart';

class CanonRules extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get title => text()();
  TextColumn get ruleText => text()();
  TextColumn get severity => text().withDefault(const Constant('hard'))();
  TextColumn get scope => text().withDefault(const Constant('global'))();
  TextColumn get scopeTargetId => text().nullable()();
  TextColumn get canonStatus => text().withDefault(const Constant('canon'))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CanonRuleConditions extends Table {
  TextColumn get id => text()();
  TextColumn get ruleId => text()();
  TextColumn get validatorType => text()();
  TextColumn get targetField => text().nullable()();
  TextColumn get operator => text().nullable()();
  TextColumn get expectedValue => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
