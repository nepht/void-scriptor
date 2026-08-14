import '../../../core/commands/app_command.dart';
import '../data/character_repository_impl.dart';

class RenameCharacterCommand extends BaseCommand {
  RenameCharacterCommand({
    required super.id,
    required super.projectId,
    required this.repository,
    required this.characterId,
    required this.oldName,
    required this.newName,
  }) : super(label: 'Rename $oldName');

  final CharacterRepositoryImpl repository;
  final String characterId;
  final String oldName;
  final String newName;

  @override
  String get commandType => 'character.rename';

  @override
  Map<String, Object?> get payload => {
    'characterId': characterId,
    'oldName': oldName,
    'newName': newName,
  };

  @override
  Map<String, Object?> get undoPayload => {
    'characterId': characterId,
    'name': oldName,
  };

  @override
  Future<void> execute() => _rename(newName);

  @override
  Future<void> undo() => _rename(oldName);

  @override
  Future<void> redo() => _rename(newName);

  Future<void> _rename(String name) async {
    final current = await repository.getCharacter(characterId);
    if (current == null || current.projectId != projectId) {
      throw StateError('Character is not available in the active project');
    }
    await repository.updateCharacter(current.copyWithName(name));
  }
}
