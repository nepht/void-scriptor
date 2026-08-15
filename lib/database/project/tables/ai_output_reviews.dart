import 'package:drift/drift.dart';

/// Records output review decisions (Step 28.16).
class AiOutputReviews extends Table {
  TextColumn get generationId => text()();
  TextColumn get status => text()(); // pending | approved | rejected
  TextColumn get feedback => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {generationId};
}
