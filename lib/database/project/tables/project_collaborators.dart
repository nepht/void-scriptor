import 'package:drift/drift.dart';

/// Project collaborators and their roles (Step 29.11).
class ProjectCollaborators extends Table {
  TextColumn get projectId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text()(); // owner / editor / viewer
  DateTimeColumn get invitedAt => dateTime()();
  DateTimeColumn get acceptedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {projectId, userId};
}
