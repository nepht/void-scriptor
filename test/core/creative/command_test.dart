import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/creative/command/creative_command.dart';
import 'package:void_scriptor/core/creative/command/command_registry.dart';

void main() {
  test('CreativeCommand holds name and description', () {
    const cmd = CreativeCommand(
      name: 'brainstorm',
      description: 'Generate ideas',
      params: ['topic'],
    );
    expect(cmd.name, 'brainstorm');
    expect(cmd.params, ['topic']);
  });

  test('CommandRegistry registers and invokes', () {
    final registry = CommandRegistry();
    registry.register(
      const CreativeCommand(
        name: 'brainstorm',
        description: 'Ideas',
        params: ['topic'],
      ),
    );
    final result = registry.invoke('brainstorm', {'topic': 'void'});
    expect(result.success, isTrue);
    expect(result.output, contains('void'));
  });

  test('CommandRegistry fails on unknown command', () {
    final registry = CommandRegistry();
    final result = registry.invoke('missing', const {});
    expect(result.success, isFalse);
  });
}
