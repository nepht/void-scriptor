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
  $ConsistencyReviewItemsTable get consistencyReviewItems =>
      attachedDatabase.consistencyReviewItems;
  $CharacterModesTable get characterModes => attachedDatabase.characterModes;
  $StoryScenesTable get storyScenes => attachedDatabase.storyScenes;
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
  $$ConsistencyReviewItemsTableTableManager get consistencyReviewItems =>
      $$ConsistencyReviewItemsTableTableManager(
        _db.attachedDatabase,
        _db.consistencyReviewItems,
      );
  $$CharacterModesTableTableManager get characterModes =>
      $$CharacterModesTableTableManager(
        _db.attachedDatabase,
        _db.characterModes,
      );
  $$StoryScenesTableTableManager get storyScenes =>
      $$StoryScenesTableTableManager(_db.attachedDatabase, _db.storyScenes);
}
