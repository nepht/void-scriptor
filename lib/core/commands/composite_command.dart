import 'app_command.dart';

class CompositeCommand extends BaseCommand {
  CompositeCommand({
    required super.id,
    required super.projectId,
    required super.label,
    required List<AppCommand> commands,
  }) : commands = List.unmodifiable(commands);

  final List<AppCommand> commands;

  @override
  Future<void> execute() async {
    for (final command in commands) {
      await command.execute();
    }
  }

  @override
  Future<void> undo() async {
    for (final command in commands.reversed) {
      await command.undo();
    }
  }

  @override
  Future<void> redo() async {
    for (final command in commands) {
      await command.redo();
    }
  }
}
