import 'package:drift/drift.dart';

class AudioWaveformCaches extends Table {
  TextColumn get id => text()();
  TextColumn get audioFileId => text()();
  IntColumn get sampleCount => integer()();
  TextColumn get peaksJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
