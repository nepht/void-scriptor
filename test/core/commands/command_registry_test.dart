import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/commands/command_registry.dart';

void main() {
  test('command registry ranks exact label and searches keywords', () async {
    final registry = CommandRegistry();
    registry.register(
      PaletteCommand(
        id: 'new-character',
        label: 'New Character',
        keywords: ['create'],
        execute: () async {},
      ),
    );
    registry.register(
      PaletteCommand(
        id: 'open-ai',
        label: 'Open AI Studio',
        keywords: ['generate'],
        execute: () async {},
      ),
    );
    expect(registry.search('create').single.id, 'new-character');
    expect(registry.search('Open AI Studio').first.id, 'open-ai');
  });
}
