import 'package:drift/drift.dart';

class AiPromptHistory extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get sceneId => text().nullable()();
  TextColumn get assetId => text().nullable()();
  TextColumn get target => text()();
  TextColumn get prompt => text()();
  TextColumn get negativePrompt => text().withDefault(const Constant(''))();
  TextColumn get provider => text().nullable()();
  TextColumn get model => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
