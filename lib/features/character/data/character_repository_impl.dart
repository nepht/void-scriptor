import 'package:drift/drift.dart';

import '../../../database/project/daos/character_dao.dart';
import '../../../database/project/project_database.dart';
import '../../../core/persistence/project_paths.dart';
import '../application/create_character_service.dart';
import '../domain/character_model.dart';
import '../domain/character_repository.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  CharacterRepositoryImpl({
    required this.database,
    required this.projectId,
    required this.paths,
  });

  final ProjectDatabase database;
  final String projectId;
  final ProjectPaths paths;

  CharacterDao get _dao => database.characterDao;

  @override
  Future<List<CharacterModel>> getCharacters() async =>
      (await _dao.getAllCharacters(projectId)).map(_fromRow).toList();

  @override
  Future<CharacterModel?> getCharacter(String id) async {
    final row = await _dao.getCharacter(id);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<CharacterModel> createCharacter({required String name}) async {
    final id = await CreateCharacterService(
      database: database,
      paths: paths,
    ).create(projectId: projectId, name: name);
    return (await getCharacter(id))!;
  }

  @override
  Future<void> updateCharacter(CharacterModel character) async {
    await database
        .update(database.characters)
        .replace(
          CharactersCompanion(
            assetId: Value(character.assetId),
            projectId: Value(character.projectId),
            displayName: Value(character.displayName),
            alias: Value(character.alias),
            biography: Value(character.biography),
            personality: Value(character.personality),
            gender: Value(character.gender),
            age: Value(character.age),
            heightCm: Value(character.heightCm),
            hair: Value(character.hair),
            eyes: Value(character.eyes),
            skin: Value(character.skin),
          ),
        );
    await (database.update(
      database.assets,
    )..where((row) => row.id.equals(character.assetId))).write(
      AssetsCompanion(
        name: Value(character.displayName),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteCharacter(String id) async {
    await database.transaction(() async {
      await (database.delete(
        database.characterIdentityProfiles,
      )..where((row) => row.characterId.equals(id))).go();
      await (database.delete(
        database.characters,
      )..where((row) => row.assetId.equals(id))).go();
      await (database.delete(
        database.assets,
      )..where((row) => row.id.equals(id))).go();
    });
  }

  CharacterModel _fromRow(Character row) => CharacterModel(
    assetId: row.assetId,
    projectId: row.projectId,
    displayName: row.displayName,
    alias: row.alias,
    biography: row.biography,
    personality: row.personality,
    gender: row.gender,
    age: row.age,
    heightCm: row.heightCm,
    hair: row.hair,
    eyes: row.eyes,
    skin: row.skin,
  );
}
