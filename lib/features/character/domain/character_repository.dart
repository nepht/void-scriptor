import 'character_identity_profile.dart';
import 'character_model.dart';
import 'character_reference.dart';

abstract interface class CharacterRepository {
  Future<List<CharacterModel>> getCharacters();
  Future<CharacterModel?> getCharacter(String id);
  Future<CharacterModel> createCharacter({required String name});
  Future<void> updateCharacter(CharacterModel character);
  Future<void> deleteCharacter(String id);
  Future<CharacterIdentityProfile?> getIdentity(String characterId);
  Future<void> updateIdentity(CharacterIdentityProfile profile);
  Future<List<CharacterReference>> getReferences(String characterId);
  Future<void> addReference(CharacterReference reference);
  Future<void> removeReference(String referenceId);
  Future<List<String>> getTags(String assetId);
  Future<void> replaceTags(String assetId, List<String> tags);
  Future<void> addRelation({
    required String id,
    required String sourceAssetId,
    required String targetAssetId,
    required String relationType,
  });
}
