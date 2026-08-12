import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/selection/selection_controller.dart';
import '../../../core/selection/selection_model.dart';
import '../../../design_system/colors/void_colors.dart';
import '../../assets/domain/asset_type.dart';
import '../../character/presentation/character_workspace_screen.dart';
import '../../wardrobe/presentation/wardrobe_workspace_screen.dart';
import '../../weapon/presentation/weapon_workspace_screen.dart';
import '../../environment/presentation/environment_workspace_screen.dart';

class WorkspaceResolver extends ConsumerWidget {
  const WorkspaceResolver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectionProvider);
    if (selection == null) return const ProjectOverview();
    return switch (selection.assetType) {
      AssetType.character => CharacterWorkspaceScreen(
        characterId: selection.assetId,
      ),
      AssetType.wardrobe => WardrobeWorkspaceScreen(
        wardrobeId: selection.assetId,
      ),
      AssetType.weapon => WeaponWorkspaceScreen(weaponId: selection.assetId),
      AssetType.environment => EnvironmentWorkspaceScreen(
        environmentId: selection.assetId,
      ),
      _ => const ProjectOverview(),
    };
  }
}

class ProjectOverview extends StatelessWidget {
  const ProjectOverview({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      'Select an asset from Explorer to open its workspace.',
      style: TextStyle(color: VoidColors.textMuted),
    ),
  );
}

void selectAsset(WidgetRef ref, SelectionModel selection) {
  ref.read(selectionProvider.notifier).select(selection);
}
