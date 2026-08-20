import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/fusion_engine.dart';

void main() {
  test('fuses matching signals inside the temporal window', () {
    const engine = FusionEngine(window: Duration(milliseconds: 500));
    final result = engine.fuse([
      const FusionSignal(
        source: 'touch',
        intent: 'select',
        confidence: .8,
        timestamp: 1000,
      ),
      const FusionSignal(
        source: 'voice',
        intent: 'edit',
        confidence: .9,
        timestamp: 1200,
      ),
    ]);

    expect(result.intent, 'edit');
    expect(result.sources, containsAll(<String>['touch', 'voice']));
    expect(result.confidence, greaterThan(.8));
    expect(result.isActionable, isTrue);
  });

  test('rejects signals outside the temporal window', () {
    const engine = FusionEngine(window: Duration(milliseconds: 500));
    final result = engine.fuse([
      const FusionSignal(
        source: 'touch',
        intent: 'select',
        confidence: .9,
        timestamp: 1000,
      ),
      const FusionSignal(
        source: 'voice',
        intent: 'edit',
        confidence: .9,
        timestamp: 1800,
      ),
    ]);

    expect(result.intent, isNull);
    expect(result.isActionable, isFalse);
  });

  test('low confidence signals do not become actionable', () {
    const engine = FusionEngine(minimumConfidence: .7);
    final result = engine.fuse([
      const FusionSignal(
        source: 'touch',
        intent: 'select',
        confidence: .4,
        timestamp: 1000,
      ),
      const FusionSignal(
        source: 'voice',
        intent: 'edit',
        confidence: .5,
        timestamp: 1050,
      ),
    ]);

    expect(result.isActionable, isFalse);
  });
}
