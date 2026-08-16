import 'creative_command.dart';

/// Registry of creative commands (Step 40.2–40.3).
class CommandRegistry {
  final Map<String, CreativeCommand> _commands = {};

  void register(CreativeCommand command) => _commands[command.name] = command;

  CreativeCommand? lookup(String name) => _commands[name];

  CommandResult invoke(String name, Map<String, dynamic> args) {
    if (!_commands.containsKey(name)) {
      return CommandResult(success: false, output: 'Unknown command: $name');
    }
    return CommandResult(success: true, output: args.toString());
  }
}
