import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/bci_compatible_input.dart';

void main() {
  test('accepts a consented compatible signal above confidence threshold', () {
    const adapter = BciCompatibleInput();
    final result = adapter.normalize(
      const BciSignal(
        command: 'select',
        confidence: .85,
        consentGranted: true,
        hardwareAvailable: true,
      ),
    );

    expect(result, const BciIntent(command: 'select', confidence: .85));
  });

  test('rejects missing consent, unavailable hardware, and low confidence', () {
    const adapter = BciCompatibleInput();
    expect(
      adapter.normalize(
        const BciSignal(
          command: 'select',
          confidence: .85,
          consentGranted: false,
          hardwareAvailable: true,
        ),
      ),
      isNull,
    );
    expect(
      adapter.normalize(
        const BciSignal(
          command: 'select',
          confidence: .85,
          consentGranted: true,
          hardwareAvailable: false,
        ),
      ),
      isNull,
    );
    expect(
      adapter.normalize(
        const BciSignal(
          command: 'select',
          confidence: .69,
          consentGranted: true,
          hardwareAvailable: true,
        ),
      ),
      isNull,
    );
  });
}
