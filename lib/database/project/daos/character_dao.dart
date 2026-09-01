import 'package:drift/drift.dart';

import '../project_database.dart';
import '../tables/characters.dart';
import '../tables/character_identity_profiles.dart';
import '../tables/character_references.dart';
import '../tables/character_scope_layers.dart';

part 'character_dao.g.dart';

@DriftAccessor(
  tables: [
    Characters,
    CharacterIdentityProfiles,
    CharacterReferences,
    CharacterCanonicalScopes,
    CharacterUniverseTimelineOverrides,
    CharacterNovelStates,
  ],
)
class CharacterDao extends DatabaseAccessor<ProjectDatabase>
    with _$CharacterDaoMixin {
  CharacterDao(super.db);

  Future<List<Character>> getAllCharacters(String projectId) => (select(
    characters,
  )..where((row) => row.projectId.equals(projectId))).get();

  Future<Character?> getCharacter(String assetId) => (select(
    characters,
  )..where((row) => row.assetId.equals(assetId))).getSingleOrNull();

  Future<CharacterIdentityProfile?> getIdentity(String characterId) => (select(
    characterIdentityProfiles,
  )..where((row) => row.characterId.equals(characterId))).getSingleOrNull();

  Future<void> updateIdentity(CharacterIdentityProfilesCompanion profile) =>
      into(characterIdentityProfiles).insertOnConflictUpdate(profile);

  Future<List<CharacterReference>> getReferences(String characterId) =>
      (select(characterReferences)
            ..where((row) => row.characterId.equals(characterId))
            ..orderBy([(row) => OrderingTerm(expression: row.priority)]))
          .get();

  Future<void> addReference(CharacterReferencesCompanion reference) =>
      into(characterReferences).insert(reference);

  Future<void> removeReference(String referenceId) => (delete(
    characterReferences,
  )..where((row) => row.id.equals(referenceId))).go();

  Future<void> removeCharacterReferences(String characterId) => (delete(
    characterReferences,
  )..where((row) => row.characterId.equals(characterId))).go();

  Future<CharacterCanonicalScope?> getCanonicalScope(String characterId) =>
      (select(
        characterCanonicalScopes,
      )..where((row) => row.characterId.equals(characterId))).getSingleOrNull();

  Future<CharacterUniverseTimelineOverride?> getUniverseTimelineScope(
    String characterId,
  ) => (select(
    characterUniverseTimelineOverrides,
  )..where((row) => row.characterId.equals(characterId))).getSingleOrNull();

  Future<CharacterNovelState?> getNovelScope(String characterId) => (select(
    characterNovelStates,
  )..where((row) => row.characterId.equals(characterId))).getSingleOrNull();

  Future<void> upsertCanonicalScope(CharacterCanonicalScopesCompanion row) =>
      into(characterCanonicalScopes).insertOnConflictUpdate(row);

  Future<void> upsertUniverseTimelineScope(
    CharacterUniverseTimelineOverridesCompanion row,
  ) => into(characterUniverseTimelineOverrides).insertOnConflictUpdate(row);

  Future<void> upsertNovelScope(CharacterNovelStatesCompanion row) =>
      into(characterNovelStates).insertOnConflictUpdate(row);

  Future<void> removeCharacterScopeRows(String characterId) async {
    await (delete(
      characterCanonicalScopes,
    )..where((row) => row.characterId.equals(characterId))).go();
    await (delete(
      characterUniverseTimelineOverrides,
    )..where((row) => row.characterId.equals(characterId))).go();
    await (delete(
      characterNovelStates,
    )..where((row) => row.characterId.equals(characterId))).go();
  }
}
