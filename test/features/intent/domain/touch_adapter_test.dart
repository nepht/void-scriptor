import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/touch_adapter.dart';

void main() {
  test('normalizes a tap into a touch intent', () {
    const adapter = TouchAdapter();
    final result = adapter.interpret(
      const TouchSample(
        targetId: 'scene-editor',
        kind: TouchKind.tap,
        confidence: .95,
      ),
    );

    expect(result.intent, TouchIntent.select);
    expect(result.targetId, 'scene-editor');
    expect(result.isActionable, isTrue);
  });

  test('combines touch and voice for the same target', () {
    const adapter = TouchAdapter();
    final result = adapter.combine(
      const TouchSample(
        targetId: 'scene-editor',
        kind: TouchKind.tap,
        confidence: .9,
      ),
      const VoiceTouchHint(targetId: 'scene-editor', command: 'edit'),
    );

    expect(result.intent, TouchIntent.edit);
    expect(result.targetId, 'scene-editor');
    expect(result.isActionable, isTrue);
  });

  test('does not combine touch and voice across targets', () {
    const adapter = TouchAdapter();
    final result = adapter.combine(
      const TouchSample(targetId: 'scene-a', kind: TouchKind.tap),
      const VoiceTouchHint(targetId: 'scene-b', command: 'edit'),
    );

    expect(result.isActionable, isFalse);
  });
}
