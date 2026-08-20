import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/voice_command.dart';

void main() {
  test('parses a natural language voice command', () {
    const parser = VoiceCommandParser();
    final command = parser.parse('Buat project baru bernama Kokuen');

    expect(command.name, VoiceCommandName.createProject);
    expect(command.arguments['name'], 'Kokuen');
    expect(command.confirmation, VoiceConfirmationLevel.required);
  });

  test('marks read-only navigation as safe', () {
    const parser = VoiceCommandParser();
    final command = parser.parse('Buka story workspace');

    expect(command.name, VoiceCommandName.openWorkspace);
    expect(command.confirmation, VoiceConfirmationLevel.none);
  });

  test('unknown commands are never executable', () {
    const parser = VoiceCommandParser();
    final command = parser.parse('Lakukan sesuatu yang aneh');

    expect(command.name, VoiceCommandName.unknown);
    expect(command.isExecutable, isFalse);
    expect(command.confirmation, VoiceConfirmationLevel.required);
  });
}
