import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/presentation/project_persistence_providers.dart';
import 'workspace_resolver.dart';

import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class WorkspacePanel extends ConsumerWidget {
  const WorkspacePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref
        .watch(projectSessionProvider)
        .valueOrNull
        ?.manifest
        .id;

    return Container(
      color: context.palette.backgroundSecondary,
      child: Column(
        children: [
          const _WorkspaceHeader(),
          const _WorkspaceTabs(),
          Expanded(
            child: projectId == null
                ? const _EmptyWorkspace()
                : const WorkspaceResolver(),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader();

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: context.palette.panelSecondary,
      border: Border(bottom: BorderSide(color: context.palette.borderSoft)),
    ),
    child: Row(
      children: [
        const Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  'Void Universe',
                  style: VoidTypography.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 10),
              Text('/', style: VoidTypography.caption),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Characters',
                  style: VoidTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.star_border, size: 17, color: context.palette.textMuted),
        const SizedBox(width: 12),
        Icon(Icons.history, size: 17, color: context.palette.textMuted),
      ],
    ),
  );
}

class _WorkspaceTabs extends StatelessWidget {
  const _WorkspaceTabs();
  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    decoration: BoxDecoration(
      color: context.palette.panel,
      border: Border(bottom: BorderSide(color: context.palette.borderSoft)),
    ),
    child: const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Tab(label: 'Overview', active: true),
          _Tab(label: 'Character Sheet'),
          _Tab(label: 'Identity'),
          _Tab(label: 'References'),
          _Tab(label: 'Story'),
          _Tab(label: 'Notes'),
        ],
      ),
    ),
  );
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, this.active = false});
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: active ? 'Overview' : '$label (deferred)',
    child: Opacity(
      opacity: active ? 1 : 0.55,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? context.palette.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? context.palette.textPrimary
                : context.palette.textMuted,
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    ),
  );
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
        const Text('Character Workspace', style: VoidTypography.caption),
        const SizedBox(height: 6),
        const Text(
          'Pilih Character dari Explorer untuk membuka Character Sheet.',
          style: VoidTypography.caption,
        ),
      ],
    ),
  );
}
