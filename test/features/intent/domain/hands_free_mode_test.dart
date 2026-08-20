import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/hands_free_mode.dart';

void main() {
  test('starts disabled and can be enabled explicitly', () {
    final mode = HandsFreeMode();

    expect(mode.isEnabled, isFalse);
    expect(mode.setEnabled(true), isTrue);
    expect(mode.isEnabled, isTrue);
  });

  test('accepts safe commands only while enabled', () {
    final mode = HandsFreeMode()..setEnabled(true);

    expect(mode.accept('save'), isTrue);
    expect(mode.accept('openWorkspace'), isTrue);

    mode.setEnabled(false);
    expect(mode.accept('save'), isFalse);
  });

  test('requires explicit confirmation for destructive commands', () {
    final mode = HandsFreeMode()..setEnabled(true);

    expect(mode.accept('delete'), isFalse);
    expect(mode.accept('delete', confirmed: true), isTrue);
    expect(mode.accept('remove', confirmed: true), isTrue);
  });
}
