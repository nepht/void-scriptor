// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bible_repository.dart';

// ignore_for_file: type=lint
mixin _$BibleRepositoryMixin on DatabaseAccessor<ProjectDatabase> {
  $BibleEntriesTable get bibleEntries => attachedDatabase.bibleEntries;
  BibleRepositoryManager get managers => BibleRepositoryManager(this);
}

class BibleRepositoryManager {
  final _$BibleRepositoryMixin _db;
  BibleRepositoryManager(this._db);
  $$BibleEntriesTableTableManager get bibleEntries =>
      $$BibleEntriesTableTableManager(_db.attachedDatabase, _db.bibleEntries);
}
