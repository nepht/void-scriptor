class SwitchAction {
  const SwitchAction({
    required this.command,
    this.requiresConfirmation = false,
  });

  final String command;
  final bool requiresConfirmation;

  @override
  bool operator ==(Object other) =>
      other is SwitchAction &&
      other.command == command &&
      other.requiresConfirmation == requiresConfirmation;

  @override
  int get hashCode => Object.hash(command, requiresConfirmation);
}

class SwitchControlAdapter {
  SwitchControlAdapter(Map<String, String> mappings)
    : _mappings = Map.unmodifiable(mappings);

  final Map<String, String> _mappings;

  SwitchAction? resolve(String switchId, {bool confirmed = false}) {
    final command = _mappings[switchId.trim()];
    if (command == null || command.trim().isEmpty) return null;

    const destructive = {'delete', 'remove', 'destroy'};
    final requiresConfirmation = destructive.contains(command);
    if (requiresConfirmation && !confirmed) return null;

    return SwitchAction(
      command: command,
      requiresConfirmation: requiresConfirmation,
    );
  }
}
