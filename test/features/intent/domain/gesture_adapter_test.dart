import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/gesture_adapter.dart';

void main() {
  test('recognizes core swipe gestures above the dead zone', () {
    const adapter = GestureAdapter(deadZone: 12);

    final result = adapter.recognize(const [
      GesturePoint(0, 0),
      GesturePoint(80, 2),
    ]);

    expect(result.type, GestureType.swipeRight);
    expect(result.confidence, greaterThan(0.8));
    expect(result.isActionable, isTrue);
  });

  test('ignores movement inside the dead zone', () {
    const adapter = GestureAdapter(deadZone: 12);

    final result = adapter.recognize(const [
      GesturePoint(10, 10),
      GesturePoint(18, 15),
    ]);

    expect(result.type, GestureType.none);
    expect(result.isActionable, isFalse);
    expect(result.confidence, 0);
  });

  test('rejects low-confidence gesture even when direction is clear', () {
    const adapter = GestureAdapter(deadZone: 12, minimumConfidence: 0.9);

    final result = adapter.recognize(const [
      GesturePoint(0, 0),
      GesturePoint(15, 0),
    ]);

    expect(result.type, GestureType.swipeRight);
    expect(result.isActionable, isFalse);
  });
}
