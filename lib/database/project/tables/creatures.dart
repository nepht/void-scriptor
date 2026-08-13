import 'package:drift/drift.dart';

class Creatures extends Table {
  TextColumn get assetId => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get speciesId => text().nullable()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get behavior => text().withDefault(const Constant(''))();
  TextColumn get abilities => text().withDefault(const Constant(''))();
  TextColumn get origin => text().withDefault(const Constant(''))();
  @override
  Set<Column<Object>> get primaryKey => {assetId};
}

class CreaturePhysicalProfiles extends Table {
  TextColumn get creatureId => text()();
  RealColumn get heightCm => real().nullable()();
  RealColumn get lengthCm => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  TextColumn get bodyStructure => text().withDefault(const Constant(''))();
  TextColumn get skinMaterial => text().withDefault(const Constant(''))();
  TextColumn get eyeDescription => text().withDefault(const Constant(''))();
  TextColumn get distinguishingFeatures =>
      text().withDefault(const Constant(''))();
  @override
  Set<Column<Object>> get primaryKey => {creatureId};
}

class CreatureAbilities extends Table {
  TextColumn get id => text()();
  TextColumn get creatureId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get powerSystemId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CreatureModes extends Table {
  TextColumn get id => text()();
  TextColumn get creatureId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get referenceSetId => text().nullable()();
  BoolColumn get defaultMode => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
