import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors/void_colors.dart';
import '../../../core/selection/selection_controller.dart';
import '../../../core/selection/selection_model.dart';
import '../../assets/domain/asset_type.dart';
import '../../character/presentation/character_controller.dart';
import '../../character/domain/character_model.dart';
import '../../projects/presentation/project_persistence_providers.dart';

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

    return Container(
      width: 245,
      decoration: const BoxDecoration(
        color: VoidColors.panel,
        border: Border(right: BorderSide(color: VoidColors.borderSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Text(
              'PROJECT EXPLORER',
              style: TextStyle(
                color: VoidColors.textMuted,
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
                const _ExplorerItem(
                  icon: Icons.checkroom_outlined,
                  label: 'Wardrobe',
                ),
                const _ExplorerItem(
                  icon: Icons.auto_fix_high_outlined,
                  label: 'Weapons',
                ),
                const _ExplorerItem(
                  icon: Icons.landscape_outlined,
                  label: 'Environment',
                ),
                const _ExplorerItem(
                  icon: Icons.menu_book_outlined,
                  label: 'Story',
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
          Icon(icon, size: 16, color: VoidColors.textMuted),
          const SizedBox(width: 9),
          Text(
            label,
            style: const TextStyle(
              color: VoidColors.textSecondary,
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
    leading: const Icon(
      Icons.people_outline,
      size: 16,
      color: VoidColors.textMuted,
    ),
    title: const Text(
      'Characters',
      style: TextStyle(color: VoidColors.textSecondary, fontSize: 12),
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
                      style: const TextStyle(
                        color: VoidColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    selected: selectedId == item.assetId,
                    selectedTileColor: VoidColors.primary.withValues(
                      alpha: 0.12,
                    ),
                    onTap: () => onSelected(item),
                  ),
                )
                .toList(),
    ),
  );
}
