import 'package:drift/drift.dart';

class AiGenerationOutputs extends Table {
  TextColumn get id => text()();
  TextColumn get jobId => text()();
  TextColumn get outputType => text()();
  TextColumn get localPath => text().nullable()();
  TextColumn get remoteUrl => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
