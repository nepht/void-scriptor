import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/correction_learning.dart';

void main() {
  test('learns a correction and applies it to the same context', () {
    final learner = CorrectionLearner(maxCorrections: 3);
    learner.record(
      const IntentCorrection(
        context: 'scene-edit',
        predictedCommand: 'save',
        correctedCommand: 'preview',
        rawPayload: 'private notes',
      ),
    );

    expect(learner.correct('scene-edit', 'save'), 'preview');
    expect(learner.corrections.single.rawPayload, isNull);
  });

  test('latest correction wins and unrelated contexts are unchanged', () {
    final learner = CorrectionLearner(maxCorrections: 3);
    learner.record(
      const IntentCorrection(
        context: 'scene-edit',
        predictedCommand: 'save',
        correctedCommand: 'preview',
      ),
    );
    learner.record(
      const IntentCorrection(
        context: 'scene-edit',
        predictedCommand: 'save',
        correctedCommand: 'export',
      ),
    );

    expect(learner.correct('scene-edit', 'save'), 'export');
    expect(learner.correct('story-edit', 'save'), 'save');
  });

  test('bounds corrections and rejects invalid capacity', () {
    expect(() => CorrectionLearner(maxCorrections: 0), throwsArgumentError);

    final learner = CorrectionLearner(maxCorrections: 1);
    learner.record(
      const IntentCorrection(
        context: 'a',
        predictedCommand: 'one',
        correctedCommand: 'two',
      ),
    );
    learner.record(
      const IntentCorrection(
        context: 'b',
        predictedCommand: 'three',
        correctedCommand: 'four',
      ),
    );

    expect(learner.corrections.map((item) => item.context), ['b']);
  });
}
