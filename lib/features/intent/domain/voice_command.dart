enum VoiceCommandName { createProject, openWorkspace, unknown }

enum VoiceConfirmationLevel { none, required }

class VoiceCommand {
  const VoiceCommand({
    required this.name,
    required this.arguments,
    required this.confirmation,
  });

  final VoiceCommandName name;
  final Map<String, String> arguments;
  final VoiceConfirmationLevel confirmation;

  bool get isExecutable => name != VoiceCommandName.unknown;
}

class VoiceCommandParser {
  const VoiceCommandParser();

  VoiceCommand parse(String raw) {
    final value = raw.trim();
    final lower = value.toLowerCase();
    if (lower.startsWith('buat project baru')) {
      const marker = 'bernama';
      final index = lower.indexOf(marker);
      final name = index < 0
          ? ''
          : value.substring(index + marker.length).trim();
      if (name.isEmpty) return _unknown();
      return VoiceCommand(
        name: VoiceCommandName.createProject,
        arguments: {'name': name},
        confirmation: VoiceConfirmationLevel.required,
      );
    }
    if (lower == 'buka story workspace' || lower == 'open story workspace') {
      return const VoiceCommand(
        name: VoiceCommandName.openWorkspace,
        arguments: {},
        confirmation: VoiceConfirmationLevel.none,
      );
    }
    return _unknown();
  }

  VoiceCommand _unknown() => const VoiceCommand(
    name: VoiceCommandName.unknown,
    arguments: {},
    confirmation: VoiceConfirmationLevel.required,
  );
}
