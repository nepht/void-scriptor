class PaletteCommand {
  const PaletteCommand({
    required this.id,
    required this.label,
    required this.execute,
    this.keywords = const [],
  });

  final String id;
  final String label;
  final List<String> keywords;
  final Future<void> Function() execute;
}

class CommandRegistry {
  final Map<String, PaletteCommand> _commands = {};

  void register(PaletteCommand command) => _commands[command.id] = command;

  List<PaletteCommand> search(String query) {
    final needle = query.trim().toLowerCase();
    final results = _commands.values.where((command) {
      if (needle.isEmpty) return true;
      return command.label.toLowerCase().contains(needle) ||
          command.keywords.any(
            (keyword) => keyword.toLowerCase().contains(needle),
          );
    }).toList();
    results.sort((a, b) {
      final aExact = a.label.toLowerCase() == needle;
      final bExact = b.label.toLowerCase() == needle;
      return (bExact ? 1 : 0).compareTo(aExact ? 1 : 0);
    });
    return List.unmodifiable(results);
  }
}
