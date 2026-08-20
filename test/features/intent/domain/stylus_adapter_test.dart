import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/stylus_adapter.dart';

void main() {
  test('recognizes a closed circle as select annotation intent', () {
    const adapter = StylusAdapter();
    final result = adapter.interpret(const [
      StylusPoint(0, 10),
      StylusPoint(10, 0),
      StylusPoint(20, 10),
      StylusPoint(10, 20),
      StylusPoint(0, 10),
    ]);

    expect(result.intent, StylusIntent.select);
    expect(result.annotationMode, isTrue);
    expect(result.confidence, greaterThan(0.7));
  });

  test('does not classify a short open stroke', () {
    const adapter = StylusAdapter();
    final result = adapter.interpret(const [
      StylusPoint(0, 0),
      StylusPoint(3, 2),
    ]);

    expect(result.intent, StylusIntent.none);
    expect(result.annotationMode, isFalse);
  });
}
