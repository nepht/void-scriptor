import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/asset_type.dart';
import '../../character/presentation/character_workspace_controller.dart';
import '../../character/presentation/widgets/character_deletion_review_dialog.dart';
import '../../character/presentation/character_controller.dart';
import '../../../core/selection/selection_controller.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import '../application/workspace_section_controller.dart';
import 'workspace_resolver.dart';

import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class WorkspacePanel extends ConsumerWidget {
  const WorkspacePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(projectSessionProvider).valueOrNull;
    final projectId = session?.manifest.id;
    final intent = ref.watch(workspaceIntentProvider);
    final selection = ref.watch(selectionProvider);
    final workspace = _WorkspacePresentation.forAssetType(
      (selection?.projectId == projectId || projectId == null
              ? selection?.assetType
              : null) ??
          (intent?.$1 == projectId ? intent?.$2 : null),
    );
    final sectionState = ref.watch(workspaceSectionProvider);
    final rememberedSection = sectionState.activeFor(workspace.kind);
    final selectedCharacter = selection?.assetType == AssetType.character
        ? ref.watch(characterWorkspaceProvider(selection!.assetId)).valueOrNull
        : null;
    final activeSection =
        (workspace.sections.contains(rememberedSection) ||
            (workspace.kind == WorkspaceKind.novel &&
                const [
                  'Versions',
                  'Export',
                  'Lore Links',
                  'Cast',
                ].contains(rememberedSection)))
        ? rememberedSection!
        : workspace.sections.first;

    return Container(
      color: context.palette.backgroundSecondary,
      child: Column(
        children: [
          _WorkspaceHeader(
            workspace: workspace,
            projectName: session?.manifest.name,
            characterName: selectedCharacter?.displayName,
            onDeleteCharacter: selectedCharacter == null || session == null
                ? null
                : () async {
                    final actions = CharacterActions(
                      ref,
                      selectedCharacter.projectId,
                      session.database,
                    );
                    final decision = await showCharacterDeletionReviewDialog(
                      context: context,
                      loadReview: () =>
                          actions.reviewDeletion(selectedCharacter.assetId),
                    );
                    if (decision != null) {
                      await actions.delete(
                        selectedCharacter.assetId,
                        decision: decision,
                      );
                    }
                  },
          ),
          _WorkspaceSections(
            workspace: workspace,
            activeSection: activeSection,
            onSelected: (section) => ref
                .read(workspaceSectionProvider.notifier)
                .activate(workspace.kind, section),
          ),
          Expanded(
            child: projectId == null
                ? const _EmptyWorkspace()
                : WorkspaceResolver(
                    activeSection: activeSection,
                    onSectionRequested: (section) => ref
                        .read(workspaceSectionProvider.notifier)
                        .activate(workspace.kind, section),
                  ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.workspace,
    this.projectName,
    this.characterName,
    this.onDeleteCharacter,
  });

  final _WorkspacePresentation workspace;
  final String? projectName;
  final String? characterName;
  final VoidCallback? onDeleteCharacter;

  @override
  Widget build(BuildContext context) {
    final resolvedProjectName = projectName?.trim();
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.palette.panelSecondary,
        border: Border(bottom: BorderSide(color: context.palette.borderSoft)),
      ),
      child: Row(
        children: [
          Icon(workspace.icon, size: 20, color: context.palette.primaryBright),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    workspace.kind == WorkspaceKind.character
                        ? 'Character'
                        : workspace.title,
                    style: VoidTypography.breadcrumb.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.palette.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (workspace.kind == WorkspaceKind.character &&
                    characterName != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_right, size: 15),
                  ),
                  Flexible(
                    child: Text(
                      characterName!,
                      style: VoidTypography.breadcrumb,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (resolvedProjectName != null &&
              resolvedProjectName.isNotEmpty &&
              workspace.kind != WorkspaceKind.character)
            Flexible(
              child: Text(
                resolvedProjectName,
                style: VoidTypography.breadcrumb,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (workspace.kind == WorkspaceKind.character) ...[
            IconButton(
              tooltip: 'Favorite',
              visualDensity: VisualDensity.compact,
              onPressed: () => _feedback(
                context,
                'Favorite is available in the next metadata slice.',
              ),
              icon: const Icon(Icons.star_border, size: 17),
            ),
            IconButton(
              tooltip: 'History',
              visualDensity: VisualDensity.compact,
              onPressed: () =>
                  _feedback(context, 'Character history is not persisted yet.'),
              icon: const Icon(Icons.history, size: 17),
            ),
            IconButton(
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
              onPressed: onDeleteCharacter,
              icon: const Icon(Icons.delete_outline, size: 17),
            ),
          ],
        ],
      ),
    );
  }

  void _feedback(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _WorkspaceSections extends StatelessWidget {
  const _WorkspaceSections({
    required this.workspace,
    required this.activeSection,
    required this.onSelected,
  });

  final _WorkspacePresentation workspace;
  final String activeSection;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    decoration: BoxDecoration(
      color: context.palette.panel,
      border: Border(bottom: BorderSide(color: context.palette.borderSoft)),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Semantics(
        label: '${workspace.title} panel structure',
        child: Row(
          children: [
            for (final section in workspace.sections)
              _WorkspaceSectionTab(
                key: ValueKey('workspace-section-$section'),
                label: section,
                selected: section == activeSection,
                onTap: () => onSelected(section),
              ),
            if (workspace.kind == WorkspaceKind.novel)
              PopupMenuButton<String>(
                tooltip: 'Document actions',
                icon: const Icon(Icons.more_horiz),
                onSelected: onSelected,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'Cast', child: Text('Cast')),
                  PopupMenuItem(value: 'Versions', child: Text('Versions')),
                  PopupMenuItem(value: 'Export', child: Text('Export')),
                  PopupMenuItem(value: 'Lore Links', child: Text('Lore Links')),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

class _WorkspaceSectionTab extends StatelessWidget {
  const _WorkspaceSectionTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 36,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected
                      ? context.palette.primaryBright
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? context.palette.textPrimary
                      : context.palette.textSecondary,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _WorkspacePresentation {
  const _WorkspacePresentation({
    required this.kind,
    required this.title,
    required this.description,
    required this.icon,
    required this.sections,
  });

  final WorkspaceKind kind;
  final String title;
  final String description;
  final IconData icon;
  final List<String> sections;

  static const novel = _WorkspacePresentation(
    kind: WorkspaceKind.novel,
    title: 'Novel Workspace',
    description: 'Manuscript, chapters, scenes, and export',
    icon: Icons.auto_stories_outlined,
    sections: ['Manuscript', 'Planning'],
  );
  static const character = _WorkspacePresentation(
    kind: WorkspaceKind.character,
    title: 'Character Workspace',
    description: 'Identity, voice, relationships, and references',
    icon: Icons.person_outline,
    sections: [
      'Overview',
      'Character Sheet',
      'Wardrobe',
      'Weapons',
      'Expressions Library',
      'Abilities',
      'Story',
      'Timeline',
      'AI Assets',
      'Relations',
      'Notes',
    ],
  );
  static const worldbuilding = _WorkspacePresentation(
    kind: WorkspaceKind.worldbuilding,
    title: 'Worldbuilding Workspace',
    description: 'Locations, factions, timeline, and lore',
    icon: Icons.public_outlined,
    sections: [
      'Location',
      'Faction',
      'Organizations',
      'Timeline',
      'Lore Notes',
    ],
  );
  static const location = _WorkspacePresentation(
    kind: WorkspaceKind.worldbuilding,
    title: 'Worldbuilding Workspace',
    description: 'Locations, factions, timeline, and lore',
    icon: Icons.place_outlined,
    sections: ['Details'],
  );
  static const creature = _WorkspacePresentation(
    kind: WorkspaceKind.worldbuilding,
    title: 'Creature Workspace',
    description:
        'Creature and companion anatomy, abilities, forms, and ecology',
    icon: Icons.pets_outlined,
    sections: ['Profile', 'Anatomy', 'Abilities', 'Modes', 'Ecology'],
  );
  static const asset = _WorkspacePresentation(
    kind: WorkspaceKind.asset,
    title: 'Asset Workspace',
    description: 'Project-scoped supporting assets',
    icon: Icons.inventory_2_outlined,
    sections: ['Details'],
  );

  static _WorkspacePresentation supportingAsset(AssetType type) =>
      switch (type) {
        AssetType.wardrobe => const _WorkspacePresentation(
          kind: WorkspaceKind.asset,
          title: 'Wardrobe Workspace',
          description: 'Outfits, variants, materials, and story use',
          icon: Icons.checkroom_outlined,
          sections: ['Details', 'Variants', 'References'],
        ),
        AssetType.weapon => const _WorkspacePresentation(
          kind: WorkspaceKind.asset,
          title: 'Weapon Workspace',
          description: 'Weapons, variants, handling, and references',
          icon: Icons.auto_fix_high_outlined,
          sections: ['Details', 'Variants', 'References'],
        ),
        AssetType.armor => const _WorkspacePresentation(
          kind: WorkspaceKind.asset,
          title: 'Armor Workspace',
          description: 'Protection, materials, ownership, and references',
          icon: Icons.shield_outlined,
          sections: ['Details', 'References'],
        ),
        AssetType.accessory => const _WorkspacePresentation(
          kind: WorkspaceKind.asset,
          title: 'Accessories Workspace',
          description: 'Jewelry, wearable details, meaning, and references',
          icon: Icons.watch_outlined,
          sections: ['Details', 'References'],
        ),
        AssetType.prop => const _WorkspacePresentation(
          kind: WorkspaceKind.asset,
          title: 'Item Workspace',
          description: 'Carried items, props, states, and story function',
          icon: Icons.inventory_2_outlined,
          sections: ['Details', 'States', 'References'],
        ),
        _ => asset,
      };

  static _WorkspacePresentation forAssetType(AssetType? type) => switch (type) {
    null || AssetType.story || AssetType.scene => novel,
    AssetType.character => character,
    AssetType.creature => creature,
    AssetType.environment => location,
    AssetType.faction ||
    AssetType.timeline ||
    AssetType.species ||
    AssetType.technology ||
    AssetType.powerSystem => worldbuilding,
    AssetType.wardrobe ||
    AssetType.weapon ||
    AssetType.armor ||
    AssetType.accessory ||
    AssetType.prop => supportingAsset(type),
    _ => asset,
  };
}

class _EmptyWorkspace extends StatelessWidget {
  const _EmptyWorkspace();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.grid_view_rounded,
          size: 38,
          color: context.palette.textMuted,
        ),
        const SizedBox(height: 14),
        const Text('Workspace', style: VoidTypography.headingMedium),
        const SizedBox(height: 6),
        const Text(
          'Buka proyek untuk bekerja di Novel, Character, atau Worldbuilding.',
          style: VoidTypography.caption,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
