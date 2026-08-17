import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/domain/ai_context_layer.dart';

void main() {
  group('AiContextLayer', () {
    test('exposes the five canonical layers in order', () {
      expect(AiContextLayer.values.map((e) => e.name), [
        'creatorPreferences',
        'currentProject',
        'currentUniverse',
        'currentCharacter',
        'currentSelection',
      ]);
    });

    test('sorts by proximity to the selection', () {
      final sorted = AiContextLayer.valuesByProximity();
      expect(sorted.first, AiContextLayer.currentSelection);
      expect(sorted.last, AiContextLayer.creatorPreferences);
    });
  });
}
