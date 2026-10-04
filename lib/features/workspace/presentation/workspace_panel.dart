import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/asset_type.dart';
import '../../../core/selection/selection_controller.dart';
import '../../projects/presentation/project_persistence_providers.dart';
import '../application/workspace_section_controller.dart';
import 'workspace_header.dart';
import 'workspace_resolver.dart';

import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class WorkspacePanel extends ConsumerWidget {
  const WorkspacePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(projectSessionProvider).value;
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
          WorkspaceHeader(
            kind: workspace.kind,
            icon: workspace.icon,
            title: workspace.title,
            projectName: session?.manifest.name,
            characterId: selection?.assetType == AssetType.character
                ? selection!.assetId
                : null,
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
    required this.icon,
    required this.sections,
  });

  final WorkspaceKind kind;
  final String title;
  final IconData icon;
  final List<String> sections;

  static const novel = _WorkspacePresentation(
    kind: WorkspaceKind.novel,
    title: 'Novel Workspace',
    icon: Icons.auto_stories_outlined,
    sections: ['Manuscript', 'Planning'],
  );
  static const character = _WorkspacePresentation(
    kind: WorkspaceKind.character,
    title: 'Character Workspace',
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
    icon: Icons.place_outlined,
    sections: ['Details'],
  );
  static const creature = _WorkspacePresentation(
    kind: WorkspaceKind.worldbuilding,
    title: 'Creature Workspace',
    icon: Icons.pets_outlined,
    sections: ['Profile', 'Anatomy', 'Abilities', 'Modes', 'Ecology'],
  );
  static const asset = _WorkspacePresentation(
    kind: WorkspaceKind.asset,
    title: 'Asset Workspace',
    icon: Icons.inventory_2_outlined,
    sections: ['Details'],
  );

  static _WorkspacePresentation supportingAsset(AssetType type) =>
      switch (type) {
        AssetType.wardrobe => const _WorkspacePresentation(
          kind: WorkspaceKind.asset,
          title: 'Wardrobe Workspace',
          icon: Icons.checkroom_outlined,
          sections: ['Details', 'Variants', 'References'],
        ),
        AssetType.weapon => const _WorkspacePresentation(
          kind: WorkspaceKind.asset,
          title: 'Weapon Workspace',
          icon: Icons.auto_fix_high_outlined,
          sections: ['Details', 'Variants', 'References'],
        ),
        AssetType.armor => const _WorkspacePresentation(
          kind: WorkspaceKind.asset,
          title: 'Armor Workspace',
          icon: Icons.shield_outlined,
          sections: ['Details', 'References'],
        ),
        AssetType.accessory => const _WorkspacePresentation(
          kind: WorkspaceKind.asset,
          title: 'Accessories Workspace',
          icon: Icons.watch_outlined,
          sections: ['Details', 'References'],
        ),
        AssetType.prop => const _WorkspacePresentation(
          kind: WorkspaceKind.asset,
          title: 'Item Workspace',
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
