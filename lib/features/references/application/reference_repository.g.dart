// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reference_repository.dart';

// ignore_for_file: type=lint
mixin _$ReferenceDaoMixin on DatabaseAccessor<ProjectDatabase> {
  $ReferencesTable get references => attachedDatabase.references;
  $ReferenceSetsTable get referenceSets => attachedDatabase.referenceSets;
  $ReferenceSetItemsTable get referenceSetItems =>
      attachedDatabase.referenceSetItems;
  $ReferenceVersionsTable get referenceVersions =>
      attachedDatabase.referenceVersions;
  $PreservationLocksTable get preservationLocks =>
      attachedDatabase.preservationLocks;
  $ConsistencyRulesTable get consistencyRules =>
      attachedDatabase.consistencyRules;
  $ConsistencyReviewsTable get consistencyReviews =>
      attachedDatabase.consistencyReviews;
  ReferenceDaoManager get managers => ReferenceDaoManager(this);
}

class ReferenceDaoManager {
  final _$ReferenceDaoMixin _db;
  ReferenceDaoManager(this._db);
  $$ReferencesTableTableManager get references =>
      $$ReferencesTableTableManager(_db.attachedDatabase, _db.references);
  $$ReferenceSetsTableTableManager get referenceSets =>
      $$ReferenceSetsTableTableManager(_db.attachedDatabase, _db.referenceSets);
  $$ReferenceSetItemsTableTableManager get referenceSetItems =>
      $$ReferenceSetItemsTableTableManager(
        _db.attachedDatabase,
        _db.referenceSetItems,
      );
  $$ReferenceVersionsTableTableManager get referenceVersions =>
      $$ReferenceVersionsTableTableManager(
        _db.attachedDatabase,
        _db.referenceVersions,
      );
  $$PreservationLocksTableTableManager get preservationLocks =>
      $$PreservationLocksTableTableManager(
        _db.attachedDatabase,
        _db.preservationLocks,
      );
  $$ConsistencyRulesTableTableManager get consistencyRules =>
      $$ConsistencyRulesTableTableManager(
        _db.attachedDatabase,
        _db.consistencyRules,
      );
  $$ConsistencyReviewsTableTableManager get consistencyReviews =>
      $$ConsistencyReviewsTableTableManager(
        _db.attachedDatabase,
        _db.consistencyReviews,
      );
}
