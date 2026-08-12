import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/selection/selection_controller.dart';
import '../../../core/selection/selection_model.dart';
import '../../../design_system/colors/void_colors.dart';
import '../../assets/domain/asset_type.dart';
import '../../character/presentation/character_workspace_screen.dart';
import '../../wardrobe/presentation/wardrobe_workspace_screen.dart';

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
      AssetType.weapon => _AssetWorkspacePlaceholder(
        assetId: selection.assetId,
        type: 'Weapon',
        icon: Icons.auto_fix_high_outlined,
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

class _AssetWorkspacePlaceholder extends StatelessWidget {
  const _AssetWorkspacePlaceholder({
    required this.assetId,
    required this.type,
    required this.icon,
  });
  final String assetId;
  final String type;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: VoidColors.primaryBright),
        const SizedBox(height: 12),
        Text(
          assetId,
          style: const TextStyle(color: VoidColors.textPrimary, fontSize: 20),
        ),
        const SizedBox(height: 6),
        Text(
          '$type Workspace',
          style: const TextStyle(color: VoidColors.textMuted),
        ),
      ],
    ),
  );
}

void selectAsset(WidgetRef ref, SelectionModel selection) {
  ref.read(selectionProvider.notifier).select(selection);
}
