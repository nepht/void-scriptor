// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_resilience_repository.dart';

// ignore_for_file: type=lint
mixin _$ProjectResilienceRepositoryMixin on DatabaseAccessor<ProjectDatabase> {
  $ExternalFilesTable get externalFiles => attachedDatabase.externalFiles;
  $ProjectBackupsTable get projectBackups => attachedDatabase.projectBackups;
  $CacheEntriesTable get cacheEntries => attachedDatabase.cacheEntries;
  $TrashEntriesTable get trashEntries => attachedDatabase.trashEntries;
  $ProjectMigrationHistoryTable get projectMigrationHistory =>
      attachedDatabase.projectMigrationHistory;
  ProjectResilienceRepositoryManager get managers =>
      ProjectResilienceRepositoryManager(this);
}

class ProjectResilienceRepositoryManager {
  final _$ProjectResilienceRepositoryMixin _db;
  ProjectResilienceRepositoryManager(this._db);
  $$ExternalFilesTableTableManager get externalFiles =>
      $$ExternalFilesTableTableManager(_db.attachedDatabase, _db.externalFiles);
  $$ProjectBackupsTableTableManager get projectBackups =>
      $$ProjectBackupsTableTableManager(
        _db.attachedDatabase,
        _db.projectBackups,
      );
  $$CacheEntriesTableTableManager get cacheEntries =>
      $$CacheEntriesTableTableManager(_db.attachedDatabase, _db.cacheEntries);
  $$TrashEntriesTableTableManager get trashEntries =>
      $$TrashEntriesTableTableManager(_db.attachedDatabase, _db.trashEntries);
  $$ProjectMigrationHistoryTableTableManager get projectMigrationHistory =>
      $$ProjectMigrationHistoryTableTableManager(
        _db.attachedDatabase,
        _db.projectMigrationHistory,
      );
}
