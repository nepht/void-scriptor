import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/selection/selection_controller.dart';
import '../../../core/selection/selection_model.dart';
import '../../assets/domain/asset_type.dart';
import '../../character/domain/character_model.dart';
import '../../character/presentation/character_controller.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import '../../wardrobe/data/wardrobe_repository_impl.dart';
import '../../wardrobe/domain/wardrobe_model.dart';
import '../../weapon/data/weapon_repository_impl.dart';
import '../../weapon/domain/weapon_model.dart';
import 'explorer_environment_group.dart';
import '../../environment/data/environment_repository_impl.dart';
import '../../environment/domain/environment_model.dart';
import '../../../database/project/project_database.dart';
import 'explorer_story_group.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

final storyExplorerProvider = FutureProvider.family<List<Asset>, String>((
  ref,
  projectId,
) async {
  final session = ref.watch(projectSessionProvider).valueOrNull;
  if (session == null || session.manifest.id != projectId) return const [];
  return (await session.database.assetDao.getAllAssets())
      .where((asset) => asset.projectId == projectId && asset.type == 'story')
      .toList(growable: false);
});

final wardrobeExplorerProvider =
    FutureProvider.family<List<WardrobeModel>, String>((ref, projectId) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null || session.manifest.id != projectId) return const [];
      return WardrobeRepositoryImpl(
        database: session.database,
        projectId: projectId,
      ).getWardrobes();
    });

final weaponExplorerProvider = FutureProvider.family<List<WeaponModel>, String>(
  (ref, projectId) async {
    final session = ref.watch(projectSessionProvider).valueOrNull;
    if (session == null || session.manifest.id != projectId) return const [];
    return WeaponRepositoryImpl(
      database: session.database,
      projectId: projectId,
    ).getWeapons();
  },
);

final environmentExplorerProvider =
    FutureProvider.family<List<EnvironmentModel>, String>((
      ref,
      projectId,
    ) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null || session.manifest.id != projectId) return const [];
      return EnvironmentRepositoryImpl(
        database: session.database,
        projectId: projectId,
      ).getEnvironments();
    });

class ExplorerPanel extends ConsumerWidget {
  const ExplorerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref
        .watch(projectSessionProvider)
        .valueOrNull
        ?.manifest
        .id;
    final characters = projectId == null
        ? const AsyncValue<List<CharacterModel>>.data([])
        : ref.watch(characterControllerProvider(projectId));
    final wardrobes = projectId == null
        ? const AsyncValue<List<WardrobeModel>>.data([])
        : ref.watch(wardrobeExplorerProvider(projectId));
    final weapons = projectId == null
        ? const AsyncValue<List<WeaponModel>>.data([])
        : ref.watch(weaponExplorerProvider(projectId));

    final environments = projectId == null
        ? const AsyncValue<List<EnvironmentModel>>.data([])
        : ref.watch(environmentExplorerProvider(projectId));
    final stories = projectId == null
        ? const AsyncValue<List<Asset>>.data([])
        : ref.watch(storyExplorerProvider(projectId));

    return Container(
      width: 245,
      decoration:  BoxDecoration(
        color: context.palette.panel,
        border: Border(right: BorderSide(color: context.palette.borderSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Text(
              'PROJECT EXPLORER',
              style: TextStyle(
                color: context.palette.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              children: [
                const _ExplorerItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                ),
                const _ExplorerItem(
                  icon: Icons.folder_outlined,
                  label: 'Projects',
                ),
                _CharacterGroup(
                  characters: characters,
                  selectedId: ref.watch(selectionProvider)?.assetId,
                  onSelected: (character) => ref
                      .read(selectionProvider.notifier)
                      .select(
                        SelectionModel(
                          assetId: character.assetId,
                          assetType: AssetType.character,
                          projectId: character.projectId,
                        ),
                      ),
                ),
                _WardrobeGroup(
                  wardrobes: wardrobes,
                  selectedId: ref.watch(selectionProvider)?.assetId,
                  onSelected: (wardrobe) => ref
                      .read(selectionProvider.notifier)
                      .select(
                        SelectionModel(
                          assetId: wardrobe.assetId,
                          assetType: AssetType.wardrobe,
                          projectId: wardrobe.projectId,
                        ),
                      ),
                ),
                _WeaponGroup(
                  weapons: weapons,
                  selectedId: ref.watch(selectionProvider)?.assetId,
                  onSelected: (weapon) => ref
                      .read(selectionProvider.notifier)
                      .select(
                        SelectionModel(
                          assetId: weapon.assetId,
                          assetType: AssetType.weapon,
                          projectId: weapon.projectId,
                        ),
                      ),
                ),
                EnvironmentGroup(
                  environments: environments,
                  selectedId: ref.watch(selectionProvider)?.assetId,
                  onSelected: (environment) => ref
                      .read(selectionProvider.notifier)
                      .select(
                        SelectionModel(
                          assetId: environment.assetId,
                          assetType: AssetType.environment,
                          projectId: environment.projectId,
                        ),
                      ),
                ),
                StoryGroup(
                  stories: stories,
                  selectedId: ref.watch(selectionProvider)?.assetId,
                  onSelected: (story) => ref
                      .read(selectionProvider.notifier)
                      .select(
                        SelectionModel(
                          assetId: story.id,
                          assetType: AssetType.story,
                          projectId: story.projectId,
                        ),
                      ),
                ),
                const _ExplorerItem(
                  icon: Icons.timeline_outlined,
                  label: 'Timeline',
                ),
                const _ExplorerItem(
                  icon: Icons.auto_awesome_outlined,
                  label: 'AI Studio',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplorerItem extends StatelessWidget {
  const _ExplorerItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () {},
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.palette.textMuted),
          const SizedBox(width: 9),
          Text(
            label,
            style:  TextStyle(
              color: context.palette.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

class _CharacterGroup extends StatelessWidget {
  const _CharacterGroup({
    required this.characters,
    required this.selectedId,
    required this.onSelected,
  });
  final AsyncValue<List<CharacterModel>> characters;
  final String? selectedId;
  final ValueChanged<CharacterModel> onSelected;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    initiallyExpanded: true,
    tilePadding: const EdgeInsets.symmetric(horizontal: 9),
    childrenPadding: const EdgeInsets.only(left: 28),
    leading:  Icon(
      Icons.people_outline,
      size: 16,
      color: context.palette.textMuted,
    ),
    title:  Text(
      'Characters',
      style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
    ),
    children: characters.when(
      loading: () => [const ListTile(dense: true, title: Text('Loading...'))],
      error: (error, _) => [ListTile(dense: true, title: Text('$error'))],
      data: (items) => items.isEmpty
          ? [const ListTile(dense: true, title: Text('No characters yet'))]
          : items
                .map(
                  (item) => ListTile(
                    dense: true,
                    minTileHeight: 30,
                    title: Text(
                      item.displayName,
                      style:  TextStyle(
                        color: context.palette.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    selected: selectedId == item.assetId,
                    selectedTileColor: context.palette.primary.withValues(
                      alpha: 0.12,
                    ),
                    onTap: () => onSelected(item),
                  ),
                )
                .toList(),
    ),
  );
}

class _WeaponGroup extends StatelessWidget {
  const _WeaponGroup({
    required this.weapons,
    required this.selectedId,
    required this.onSelected,
  });

  final AsyncValue<List<WeaponModel>> weapons;
  final String? selectedId;
  final ValueChanged<WeaponModel> onSelected;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    initiallyExpanded: true,
    tilePadding: const EdgeInsets.symmetric(horizontal: 9),
    childrenPadding: const EdgeInsets.only(left: 28),
    leading:  Icon(
      Icons.auto_fix_high_outlined,
      size: 16,
      color: context.palette.textMuted,
    ),
    title:  Text(
      'Weapons',
      style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
    ),
    children: weapons.when(
      loading: () => [const ListTile(dense: true, title: Text('Loading...'))],
      error: (error, _) => [ListTile(dense: true, title: Text('$error'))],
      data: (items) => items.isEmpty
          ? [const ListTile(dense: true, title: Text('No weapons yet'))]
          : items
                .map(
                  (item) => ListTile(
                    dense: true,
                    minTileHeight: 30,
                    title: Text(
                      item.name,
                      style:  TextStyle(
                        color: context.palette.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    selected: selectedId == item.assetId,
                    selectedTileColor: context.palette.primary.withValues(
                      alpha: 0.12,
                    ),
                    onTap: () => onSelected(item),
                  ),
                )
                .toList(),
    ),
  );
}

class _WardrobeGroup extends StatelessWidget {
  const _WardrobeGroup({
    required this.wardrobes,
    required this.selectedId,
    required this.onSelected,
  });
  final AsyncValue<List<WardrobeModel>> wardrobes;
  final String? selectedId;
  final ValueChanged<WardrobeModel> onSelected;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    initiallyExpanded: true,
    tilePadding: const EdgeInsets.symmetric(horizontal: 9),
    childrenPadding: const EdgeInsets.only(left: 28),
    leading:  Icon(
      Icons.checkroom_outlined,
      size: 16,
      color: context.palette.textMuted,
    ),
    title:  Text(
      'Wardrobe',
      style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
    ),
    children: wardrobes.when(
      loading: () => [const ListTile(dense: true, title: Text('Loading...'))],
      error: (error, _) => [ListTile(dense: true, title: Text('$error'))],
      data: (items) => items.isEmpty
          ? [const ListTile(dense: true, title: Text('No wardrobes yet'))]
          : items
                .map(
                  (item) => ListTile(
                    dense: true,
                    minTileHeight: 30,
                    title: Text(
                      item.name,
                      style:  TextStyle(
                        color: context.palette.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    selected: selectedId == item.assetId,
                    selectedTileColor: context.palette.primary.withValues(
                      alpha: 0.12,
                    ),
                    onTap: () => onSelected(item),
                  ),
                )
                .toList(),
    ),
  );
}
