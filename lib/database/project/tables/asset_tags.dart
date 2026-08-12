import 'package:drift/drift.dart';

class AssetTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get assetId => text()();
  TextColumn get tag => text()();
}
