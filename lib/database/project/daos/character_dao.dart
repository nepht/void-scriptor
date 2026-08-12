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

  Future<List<CharacterReference>> getReferences(String characterId) =>
      (select(characterReferences)
            ..where((row) => row.characterId.equals(characterId))
            ..orderBy([(row) => OrderingTerm(expression: row.priority)]))
          .get();
}
