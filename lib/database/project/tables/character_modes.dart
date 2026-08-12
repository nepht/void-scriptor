import 'package:drift/drift.dart';

class CharacterModes extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get characterId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  TextColumn get thumbnailPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
