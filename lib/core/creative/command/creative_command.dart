/// A creative command (Step 40.1).
class CreativeCommand {
  const CreativeCommand({
    required this.name,
    required this.description,
    this.params = const [],
  });

  final String name;
  final String description;
  final List<String> params;
}

/// Result of a command invocation (Step 40.2).
class CommandResult {
  const CommandResult({required this.success, required this.output});

  final bool success;
  final String output;
}
