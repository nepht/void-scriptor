import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/domain/scene_continuity.dart';

void main() {
  test(
    'continuity validator warns when a later scene conflicts with prior state',
    () {
      final warnings = SceneContinuityValidator.validate([
        const ContinuityEvent(
          sceneOrder: 1,
          targetAssetId: 'sword',
          afterState: 'destroyed',
        ),
        const ContinuityEvent(
          sceneOrder: 2,
          targetAssetId: 'sword',
          beforeState: 'intact',
        ),
      ]);
      expect(warnings.single.targetAssetId, 'sword');
    },
  );

  test('scene context produces an AI-ready summary', () {
    const context = ResolvedSceneContext(
      storyTitle: 'Rise of the Void',
      sceneTitle: 'Landing',
      durationSeconds: 10,
      characters: ['Qowner — Combat Mode'],
      environment: 'Neo City / Main Street / Clear / Noon',
      beats: ['Qowner descends.'],
    );
    expect(context.toPrompt(), contains('Rise of the Void'));
    expect(context.toPrompt(), contains('Qowner — Combat Mode'));
  });
}
