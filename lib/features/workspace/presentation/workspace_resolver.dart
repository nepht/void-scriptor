import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/selection/selection_controller.dart';
import '../../../core/selection/selection_model.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import '../../assets/domain/asset_type.dart';
import '../../character/presentation/character_workspace_screen.dart';
import '../../wardrobe/presentation/wardrobe_workspace_screen.dart';
import '../../weapon/presentation/weapon_workspace_screen.dart';
import '../../environment/presentation/environment_workspace_screen.dart';
import '../../story/data/story_repository_impl.dart';
import '../../story/presentation/story_workspace_screen.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class WorkspaceResolver extends ConsumerWidget {
  const WorkspaceResolver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectionProvider);
    final session = ref.watch(projectSessionProvider).valueOrNull;
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
      AssetType.story => StoryWorkspaceScreen(
        storyId: selection.assetId,
        repository: session == null
            ? null
            : StoryRepositoryImpl(
                database: session.database,
                projectId: session.manifest.id,
              ),
        exportDirectory: session?.package.exportDirectory,
      ),
      _ => const ProjectOverview(),
    };
  }
}

class ProjectOverview extends StatelessWidget {
  const ProjectOverview({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      'Select an asset from Explorer to open its workspace.',
      style: TextStyle(color: context.palette.textMuted),
    ),
  );
}

void selectAsset(WidgetRef ref, SelectionModel selection) {
  ref.read(selectionProvider.notifier).select(selection);
}
