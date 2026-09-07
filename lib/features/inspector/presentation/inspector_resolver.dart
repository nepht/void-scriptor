import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/selection/selection_controller.dart';
import '../../../features/assets/domain/asset_type.dart';
import '../../../features/projects/presentation/project_persistence_providers.dart';
import 'inspectors/character_inspector.dart';
import 'inspectors/empty_inspector.dart';
import 'inspectors/weapon_inspector.dart';
import 'inspectors/wardrobe_inspector.dart';
import '../../environment/presentation/environment_inspector.dart';
import '../../story/presentation/story_inspector.dart';

class InspectorResolver extends ConsumerWidget {
  const InspectorResolver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectionProvider);
    final activeProjectId = ref.watch(currentProjectIdProvider);
    // 145.43 cross-project fix (run110): a selection made in another project
    // (stamped with its projectId) must not surface stale content after a
    // project switch; treat it as no selection until the user picks again.
    if (selection == null ||
        (selection.projectId != null &&
            selection.projectId != activeProjectId)) {
      return const EmptyInspector();
    }
    // Typed inspectors render Material widgets (ListTile, InkWell); guarantee
    // a Material ancestor without adding any visual surface.
    return Material(
      type: MaterialType.transparency,
      child: switch (selection.assetType) {
        AssetType.character => CharacterInspector(
          characterId: selection.assetId,
        ),
        AssetType.wardrobe => WardrobeInspector(wardrobeId: selection.assetId),
        AssetType.weapon => WeaponInspector(weaponId: selection.assetId),
        AssetType.environment => EnvironmentInspector(
          environmentId: selection.assetId,
        ),
        AssetType.story => StoryInspector(storyId: selection.assetId),
        _ => const EmptyInspector(),
      },
    );
  }
}
