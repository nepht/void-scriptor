import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/gaze_adapter.dart';

void main() {
  test('focuses after stable dwell without producing a click', () {
    const adapter = GazeAdapter(dwellDuration: Duration(milliseconds: 500));
    final result = adapter.evaluate(
      const GazeSample(
        targetId: 'scene-editor',
        confidence: 0.95,
        dwell: Duration(milliseconds: 700),
      ),
    );

    expect(result.focusedTargetId, 'scene-editor');
    expect(result.isFocused, isTrue);
    expect(result.activate, isFalse);
  });

  test('does not focus moving or low-confidence gaze', () {
    const adapter = GazeAdapter(dwellDuration: Duration(milliseconds: 500));
    final result = adapter.evaluate(
      const GazeSample(
        targetId: 'scene-editor',
        confidence: 0.4,
        dwell: Duration(milliseconds: 700),
        isStable: false,
      ),
    );

    expect(result.focusedTargetId, isNull);
    expect(result.isFocused, isFalse);
    expect(result.activate, isFalse);
  });
}
