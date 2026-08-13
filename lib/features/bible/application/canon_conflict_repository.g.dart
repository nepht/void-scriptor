// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canon_conflict_repository.dart';

// ignore_for_file: type=lint
mixin _$CanonConflictRepositoryMixin on DatabaseAccessor<ProjectDatabase> {
  $CanonConflictsTable get canonConflicts => attachedDatabase.canonConflicts;
  $CanonRuleExceptionsTable get canonRuleExceptions =>
      attachedDatabase.canonRuleExceptions;
  CanonConflictRepositoryManager get managers =>
      CanonConflictRepositoryManager(this);
}

class CanonConflictRepositoryManager {
  final _$CanonConflictRepositoryMixin _db;
  CanonConflictRepositoryManager(this._db);
  $$CanonConflictsTableTableManager get canonConflicts =>
      $$CanonConflictsTableTableManager(
        _db.attachedDatabase,
        _db.canonConflicts,
      );
  $$CanonRuleExceptionsTableTableManager get canonRuleExceptions =>
      $$CanonRuleExceptionsTableTableManager(
        _db.attachedDatabase,
        _db.canonRuleExceptions,
      );
}
