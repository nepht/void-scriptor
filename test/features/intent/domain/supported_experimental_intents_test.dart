import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/supported_experimental_intents.dart';

void main() {
  test('exposes versioned opt-in experimental intents', () {
    const registry = ExperimentalIntentRegistry();
    expect(registry.version, '0.51-experimental');
    expect(registry.isSupported('select'), isTrue);
    expect(registry.isSupported('delete'), isFalse);
  });

  test('returns a safe fallback for unsupported intents', () {
    const registry = ExperimentalIntentRegistry();
    expect(registry.resolve('unknown'), 'standardInput');
    expect(registry.resolve('select'), 'select');
  });
}
