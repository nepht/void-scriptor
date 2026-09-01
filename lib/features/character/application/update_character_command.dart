import '../../../core/commands/app_command.dart';
import '../data/character_repository_impl.dart';
import '../domain/character_model.dart';

Map<String, Object?> characterToData(CharacterModel value) => {
  'assetId': value.assetId,
  'projectId': value.projectId,
  'displayName': value.displayName,
  'alias': value.alias,
  'biography': value.biography,
  'personality': value.personality,
  'gender': value.gender,
  'age': value.age,
  'heightCm': value.heightCm,
  'hair': value.hair,
  'eyes': value.eyes,
  'skin': value.skin,
  'voice': value.voice,
};

CharacterModel characterFromData(Map<String, Object?> value) => CharacterModel(
  assetId: value['assetId']! as String,
  projectId: value['projectId']! as String,
  displayName: value['displayName']! as String,
  alias: value['alias'] as String? ?? '',
  biography: value['biography'] as String? ?? '',
  personality: value['personality'] as String? ?? '',
  gender: value['gender'] as String? ?? '',
  age: value['age'] as int?,
  heightCm: (value['heightCm'] as num?)?.toDouble(),
  hair: value['hair'] as String? ?? '',
  eyes: value['eyes'] as String? ?? '',
  skin: value['skin'] as String? ?? '',
  voice: value['voice'] as String? ?? '',
);

class UpdateCharacterCommand extends BaseCommand {
  UpdateCharacterCommand({
    required super.id,
    required super.projectId,
    required this.repository,
    required this.oldValue,
    required this.newValue,
    super.label = 'Update Character',
  });

  final CharacterRepositoryImpl repository;
  final CharacterModel oldValue;
  final CharacterModel newValue;

  @override
  String get commandType => 'character.update';

  @override
  Map<String, Object?> get payload => {
    'characterId': newValue.assetId,
    'old': characterToData(oldValue),
    'new': characterToData(newValue),
  };

  @override
  Map<String, Object?> get undoPayload => characterToData(oldValue);

  @override
  Future<void> execute() => _apply(newValue);

  @override
  Future<void> undo() => _apply(oldValue);

  @override
  Future<void> redo() => _apply(newValue);

  Future<void> _apply(CharacterModel value) async {
    if (value.projectId != projectId || oldValue.assetId != newValue.assetId) {
      throw StateError('Character update does not belong to active project');
    }
    final current = await repository.getCharacter(value.assetId);
    if (current == null || current.projectId != projectId) {
      throw StateError('Character is not available in the active project');
    }
    await repository.updateCharacter(value);
  }
}
