// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_dao.dart';

// ignore_for_file: type=lint
mixin _$CharacterDaoMixin on DatabaseAccessor<ProjectDatabase> {
  $CharactersTable get characters => attachedDatabase.characters;
  $CharacterIdentityProfilesTable get characterIdentityProfiles =>
      attachedDatabase.characterIdentityProfiles;
  $CharacterReferencesTable get characterReferences =>
      attachedDatabase.characterReferences;
  $CharacterCanonicalScopesTable get characterCanonicalScopes =>
      attachedDatabase.characterCanonicalScopes;
  $CharacterUniverseTimelineOverridesTable
  get characterUniverseTimelineOverrides =>
      attachedDatabase.characterUniverseTimelineOverrides;
  $CharacterNovelStatesTable get characterNovelStates =>
      attachedDatabase.characterNovelStates;
  CharacterDaoManager get managers => CharacterDaoManager(this);
}

class CharacterDaoManager {
  final _$CharacterDaoMixin _db;
  CharacterDaoManager(this._db);
  $$CharactersTableTableManager get characters =>
      $$CharactersTableTableManager(_db.attachedDatabase, _db.characters);
  $$CharacterIdentityProfilesTableTableManager get characterIdentityProfiles =>
      $$CharacterIdentityProfilesTableTableManager(
        _db.attachedDatabase,
        _db.characterIdentityProfiles,
      );
  $$CharacterReferencesTableTableManager get characterReferences =>
      $$CharacterReferencesTableTableManager(
        _db.attachedDatabase,
        _db.characterReferences,
      );
  $$CharacterCanonicalScopesTableTableManager get characterCanonicalScopes =>
      $$CharacterCanonicalScopesTableTableManager(
        _db.attachedDatabase,
        _db.characterCanonicalScopes,
      );
  $$CharacterUniverseTimelineOverridesTableTableManager
  get characterUniverseTimelineOverrides =>
      $$CharacterUniverseTimelineOverridesTableTableManager(
        _db.attachedDatabase,
        _db.characterUniverseTimelineOverrides,
      );
  $$CharacterNovelStatesTableTableManager get characterNovelStates =>
      $$CharacterNovelStatesTableTableManager(
        _db.attachedDatabase,
        _db.characterNovelStates,
      );
}
