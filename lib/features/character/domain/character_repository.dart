import 'character_model.dart';

abstract interface class CharacterRepository {
  Future<List<CharacterModel>> getCharacters();
  Future<CharacterModel?> getCharacter(String id);
  Future<CharacterModel> createCharacter({required String name});
  Future<void> updateCharacter(CharacterModel character);
  Future<void> deleteCharacter(String id);
}
