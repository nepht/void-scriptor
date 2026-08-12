import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/selection/selection_controller.dart';
import '../../../features/assets/domain/asset_type.dart';
import 'inspectors/character_inspector.dart';
import 'inspectors/empty_inspector.dart';
import 'inspectors/weapon_inspector.dart';
import 'inspectors/wardrobe_inspector.dart';
import '../../environment/presentation/environment_inspector.dart';

class InspectorResolver extends ConsumerWidget {
  const InspectorResolver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectionProvider);
    if (selection == null) return const EmptyInspector();
    return switch (selection.assetType) {
      AssetType.character => CharacterInspector(characterId: selection.assetId),
      AssetType.wardrobe => WardrobeInspector(wardrobeId: selection.assetId),
      AssetType.weapon => WeaponInspector(weaponId: selection.assetId),
      AssetType.environment => EnvironmentInspector(
        environmentId: selection.assetId,
      ),
      _ => const EmptyInspector(),
    };
  }
}
