import 'package:drift/drift.dart';

/// Comments attached to project entities (Step 29.12).
class ProjectComments extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get authorId => text()();
  TextColumn get targetType => text()(); // character / scene / ...
  TextColumn get targetId => text()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime()();
}
