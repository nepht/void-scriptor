import 'package:drift/drift.dart';

import '../project_database.dart';
import '../tables/characters.dart';
import '../tables/character_identity_profiles.dart';
import '../tables/character_references.dart';

part 'character_dao.g.dart';

@DriftAccessor(
  tables: [Characters, CharacterIdentityProfiles, CharacterReferences],
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
}
