import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 43.7 — Creator Workspace.
///
/// Setiap kreator mempunyai: My Projects, My Characters, My Worlds,
/// My Assets, My Stories, My AI Agents, My Workflows, Portfolio, Archive.
/// Workspace menggunakan Asset Core yang sudah dibuat sebelumnya,
/// bukan database aset kedua yang terpisah.
class CreatorWorkspaceScreen extends StatelessWidget {
  const CreatorWorkspaceScreen({super.key});

  static const sections = <_WorkspaceSection>[
    _WorkspaceSection('My Projects', Icons.folder_copy_outlined),
    _WorkspaceSection('My Characters', Icons.person_outline),
    _WorkspaceSection('My Worlds', Icons.public_outlined),
    _WorkspaceSection('My Assets', Icons.inventory_2_outlined),
    _WorkspaceSection('My Stories', Icons.menu_book_outlined),
    _WorkspaceSection('My AI Agents', Icons.smart_toy_outlined),
    _WorkspaceSection('My Workflows', Icons.account_tree_outlined),
    _WorkspaceSection('Portfolio', Icons.work_outline),
    _WorkspaceSection('Archive', Icons.archive_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Workspace'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            final crossAxisCount = wide ? 3 : 2;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(VoidSpacing.lg),
              child: GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: VoidSpacing.md,
                crossAxisSpacing: VoidSpacing.md,
                childAspectRatio: wide ? 2.8 : 1.6,
                children: [for (final s in sections) _SectionCard(section: s)],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WorkspaceSection {
  const _WorkspaceSection(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final _WorkspaceSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VoidSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(section.icon, color: context.palette.primary, size: 22),
            const SizedBox(width: VoidSpacing.sm),
            Text(
              section.label,
              style: VoidTypography.body.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
