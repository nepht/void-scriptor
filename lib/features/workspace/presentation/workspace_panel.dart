import 'package:flutter/material.dart';

import '../../../design_system/colors/void_colors.dart';
import '../../../design_system/typography/void_typography.dart';

class WorkspacePanel extends StatelessWidget {
  const WorkspacePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VoidColors.backgroundSecondary,
      child: Column(
        children: [
          const _WorkspaceHeader(),
          const _WorkspaceTabs(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              child: const _EmptyWorkspace(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: VoidColors.panelSecondary,
        border: Border(bottom: BorderSide(color: VoidColors.borderSoft)),
      ),
      child: const Row(
        children: [
          Text('Void Universe', style: VoidTypography.title),
          SizedBox(width: 10),
          Text('/', style: VoidTypography.caption),
          SizedBox(width: 10),
          Text('Characters', style: VoidTypography.caption),
          Spacer(),
          Icon(Icons.star_border, size: 17, color: VoidColors.textMuted),
          SizedBox(width: 12),
          Icon(Icons.history, size: 17, color: VoidColors.textMuted),
        ],
      ),
    );
  }
}

class _WorkspaceTabs extends StatelessWidget {
  const _WorkspaceTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: VoidColors.panel,
        border: Border(bottom: BorderSide(color: VoidColors.borderSoft)),
      ),
      child: const Row(
        children: [
          _Tab(label: 'Overview', active: true),
          _Tab(label: 'Character Sheet'),
          _Tab(label: 'Wardrobe'),
          _Tab(label: 'Weapons'),
          _Tab(label: 'Story'),
          _Tab(label: 'Timeline'),
          _Tab(label: 'Notes'),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: active ? VoidColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? VoidColors.textPrimary : VoidColors.textMuted,
          fontSize: 11,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _EmptyWorkspace extends StatelessWidget {
  const _EmptyWorkspace();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.grid_view_rounded,
            size: 38,
            color: VoidColors.textMuted,
          ),
          SizedBox(height: 14),
          Text(
            'Character Workspace',
            style: VoidTypography.headingMedium,
          ),
          SizedBox(height: 6),
          Text(
            'Character Sheet akan dibangun pada sprint berikutnya.',
            style: VoidTypography.caption,
          ),
        ],
      ),
    );
  }
}
