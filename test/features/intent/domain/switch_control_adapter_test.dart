import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/switch_control_adapter.dart';

void main() {
  test('maps registered switches to safe commands', () {
    final adapter = SwitchControlAdapter({
      'primary': 'select',
      'secondary': 'next',
    });

    expect(adapter.resolve('primary'), const SwitchAction(command: 'select'));
    expect(adapter.resolve('secondary'), const SwitchAction(command: 'next'));
  });

  test('rejects unknown or blank switch input', () {
    final adapter = SwitchControlAdapter({'primary': 'select'});

    expect(adapter.resolve('unknown'), isNull);
    expect(adapter.resolve(' '), isNull);
  });

  test('requires confirmation for destructive mappings', () {
    final adapter = SwitchControlAdapter({'primary': 'delete'});

    expect(adapter.resolve('primary'), isNull);
    expect(
      adapter.resolve('primary', confirmed: true),
      const SwitchAction(command: 'delete', requiresConfirmation: true),
    );
  });
}
