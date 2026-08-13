import 'package:drift/drift.dart';

class ConsistencyRules extends Table {
  TextColumn get id => text()();
  TextColumn get assetId => text()();
  TextColumn get type => text()();
  TextColumn get description => text()();
  TextColumn get severity => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ConsistencyReviews extends Table {
  TextColumn get id => text()();
  TextColumn get generationOutputId => text()();
  TextColumn get assetId => text()();
  TextColumn get status => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get reviewedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ConsistencyReviewItems extends Table {
  TextColumn get id => text()();
  TextColumn get reviewId => text()();
  TextColumn get ruleId => text()();
  TextColumn get status => text()();
  TextColumn get note => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
