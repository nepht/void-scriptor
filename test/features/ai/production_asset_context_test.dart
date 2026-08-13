import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/application/ai_scene_asset_context_resolver.dart';
import 'package:void_scriptor/features/ai/domain/prompt_target.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/references/domain/reference_models.dart';
import 'package:void_scriptor/features/scene_assets/domain/scene_asset_instance.dart';
import 'package:void_scriptor/features/timeline/domain/timeline_model.dart';

void main() {
  test('production enums expose creature vehicle and prop contracts', () {
    expect(
      PromptTarget.values,
      containsAll([
        PromptTarget.creature,
        PromptTarget.vehicle,
        PromptTarget.prop,
      ]),
    );
    expect(
      PreservationLockType.values,
      containsAll([
        PreservationLockType.creatureGeometry,
        PreservationLockType.vehicleGeometry,
        PreservationLockType.propGeometry,
      ]),
    );
    expect(
      TimelineTrackType.values,
      containsAll([
        TimelineTrackType.creature,
        TimelineTrackType.vehicle,
        TimelineTrackType.prop,
      ]),
    );
  });

  test('AI context prioritizes critical assets within reference budget', () {
    final result = AiSceneAssetContextResolver().resolve(
      [
        const AiSceneAssetCandidate(
          assetId: 'coffee',
          name: 'Coffee Cup',
          type: AssetType.prop,
          priority: SceneContextPriority.optional,
          references: ['coffee-ref'],
        ),
        const AiSceneAssetCandidate(
          assetId: 'dice',
          name: 'Void Dice',
          type: AssetType.prop,
          priority: SceneContextPriority.normal,
          storyCritical: true,
          references: ['dice-front', 'dice-side'],
        ),
        const AiSceneAssetCandidate(
          assetId: 'byte',
          name: 'Byte',
          type: AssetType.creature,
          priority: SceneContextPriority.high,
          state: 'Combat',
          references: ['byte-front'],
        ),
        const AiSceneAssetCandidate(
          assetId: 'ship',
          name: 'Neo Interceptor',
          type: AssetType.vehicle,
          priority: SceneContextPriority.normal,
          references: ['ship-front'],
        ),
      ],
      maxAssets: 3,
      maxReferences: 3,
    );
    expect(result.map((item) => item.assetId), ['byte', 'dice', 'ship']);
    expect(result.expand((item) => item.references).length, 3);
    expect(result.first.state, 'Combat');
  });
}
