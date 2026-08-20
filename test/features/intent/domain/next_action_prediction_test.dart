import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/next_action_prediction.dart';

void main() {
  test('predicts save after select then edit on the same target', () {
    final predictor = NextActionPredictor();

    final result = predictor.predict(const [
      IntentHistoryEntry(intent: 'select', targetId: 'scene-1'),
      IntentHistoryEntry(intent: 'edit', targetId: 'scene-1'),
    ]);

    expect(
      result,
      const NextActionPrediction(intent: 'save', targetId: 'scene-1'),
    );
  });

  test('does not predict from empty or unsupported history', () {
    final predictor = NextActionPredictor();

    expect(predictor.predict(const []), isNull);
    expect(
      predictor.predict(const [
        IntentHistoryEntry(intent: 'delete', targetId: 'scene-1'),
      ]),
      isNull,
    );
  });

  test('does not cross target boundaries', () {
    final predictor = NextActionPredictor();

    final result = predictor.predict(const [
      IntentHistoryEntry(intent: 'select', targetId: 'scene-1'),
      IntentHistoryEntry(intent: 'edit', targetId: 'scene-2'),
    ]);

    expect(result, isNull);
  });
}
