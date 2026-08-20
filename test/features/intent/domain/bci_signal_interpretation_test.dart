import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/bci_signal_interpretation.dart';

void main() {
  test('interprets only supported experimental intents', () {
    const interpreter = BciSignalInterpreter();
    expect(
      interpreter.interpret('select', .8),
      const BciInterpretation('select'),
    );
    expect(interpreter.interpret('delete', .8), isNull);
  });

  test('rejects low confidence and unknown commands', () {
    const interpreter = BciSignalInterpreter();
    expect(interpreter.interpret('select', .69), isNull);
    expect(interpreter.interpret('unknown', .99), isNull);
  });
}
