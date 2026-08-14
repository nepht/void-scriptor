import 'app_command.dart';
import '../../features/project_resilience/application/command_history_repository.dart';

typedef CommandFactory = AppCommand Function(CommandHistoryRecord record);

abstract final class CommandTypes {
  static const renameAsset = 'asset.rename';
  static const updateCharacter = 'character.update';
  static const moveTimelineClip = 'timeline.clip.move';
  static const deleteAsset = 'asset.delete';
  static const createRelation = 'relation.create';
}

class CommandTypeRegistry {
  final Map<String, CommandFactory> _factories = {};

  void register(String type, CommandFactory factory) {
    if (type.trim().isEmpty) {
      throw ArgumentError.value(type, 'type', 'must not be empty');
    }
    _factories[type] = factory;
  }

  AppCommand create(CommandHistoryRecord record) {
    final factory = _factories[record.commandType];
    if (factory == null) {
      throw UnsupportedError(
        'No command factory registered for ${record.commandType}',
      );
    }
    return factory(record);
  }
}
