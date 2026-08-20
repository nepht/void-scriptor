import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/context_fusion.dart';

void main() {
  test('prefers a context-compatible intent', () {
    const engine = ContextFusionEngine();
    final result = engine.resolve(const [
      ContextualSignal(source: 'touch', intent: 'select', confidence: .8),
      ContextualSignal(source: 'voice', intent: 'delete', confidence: .95),
    ], const IntentContextHint(activeMode: 'review'));

    expect(result.intent, 'select');
    expect(result.hasConflict, isTrue);
    expect(result.requiresConfirmation, isTrue);
  });

  test('uses explicit intent priority when context does not decide', () {
    const engine = ContextFusionEngine();
    final result = engine.resolve(const [
      ContextualSignal(source: 'touch', intent: 'select', confidence: .8),
      ContextualSignal(source: 'voice', intent: 'edit', confidence: .8),
    ], const IntentContextHint(activeMode: 'writing'));

    expect(result.intent, 'edit');
    expect(result.priority, 2);
  });

  test('does not resolve a low-confidence conflict', () {
    const engine = ContextFusionEngine(minimumConfidence: .7);
    final result = engine.resolve(const [
      ContextualSignal(source: 'touch', intent: 'select', confidence: .4),
      ContextualSignal(source: 'voice', intent: 'delete', confidence: .5),
    ], const IntentContextHint(activeMode: 'review'));

    expect(result.intent, isNull);
    expect(result.hasConflict, isFalse);
  });
}
