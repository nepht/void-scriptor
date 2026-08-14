import '../../../core/commands/app_command.dart';
import '../data/character_repository_impl.dart';
import '../domain/character_identity_profile.dart';

Map<String, Object?> characterIdentityToData(CharacterIdentityProfile value) =>
    {
      'characterId': value.characterId,
      'faceLock': value.faceLock,
      'hairLock': value.hairLock,
      'bodyLock': value.bodyLock,
      'colorLock': value.colorLock,
      'outfitLock': value.outfitLock,
      'weaponLock': value.weaponLock,
      'accessoryLock': value.accessoryLock,
      'notes': value.notes,
    };

CharacterIdentityProfile characterIdentityFromData(
  Map<String, Object?> value,
) => CharacterIdentityProfile(
  characterId: value['characterId']! as String,
  faceLock: value['faceLock']! as bool,
  hairLock: value['hairLock']! as bool,
  bodyLock: value['bodyLock']! as bool,
  colorLock: value['colorLock']! as bool,
  outfitLock: value['outfitLock']! as bool,
  weaponLock: value['weaponLock']! as bool,
  accessoryLock: value['accessoryLock']! as bool,
  notes: value['notes'] as String? ?? '',
);

class UpdateCharacterIdentityCommand extends BaseCommand {
  UpdateCharacterIdentityCommand({
    required super.id,
    required super.projectId,
    required this.repository,
    required this.oldValue,
    required this.newValue,
  }) : super(label: 'Update Character Identity');

  final CharacterRepositoryImpl repository;
  final CharacterIdentityProfile oldValue;
  final CharacterIdentityProfile newValue;

  @override
  String get commandType => 'character.identity.update';

  @override
  Map<String, Object?> get payload => {
    'characterId': newValue.characterId,
    'old': characterIdentityToData(oldValue),
    'new': characterIdentityToData(newValue),
  };

  @override
  Map<String, Object?> get undoPayload => characterIdentityToData(oldValue);

  @override
  Future<void> execute() => _apply(newValue);

  @override
  Future<void> undo() => _apply(oldValue);

  @override
  Future<void> redo() => _apply(newValue);

  Future<void> _apply(CharacterIdentityProfile value) async {
    if (oldValue.characterId != newValue.characterId) {
      throw StateError('Identity update targets different characters');
    }
    final character = await repository.getCharacter(value.characterId);
    if (character == null || character.projectId != projectId) {
      throw StateError('Character is not available in the active project');
    }
    await repository.updateIdentity(value);
  }
}
