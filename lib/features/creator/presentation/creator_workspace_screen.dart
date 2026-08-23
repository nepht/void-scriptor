import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import '../application/creator_studio_controller.dart';
import '../domain/creator_workspace_section.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 43.7 — Creator Workspace.
///
/// Setiap kreator mempunyai: My Projects, My Characters, My Worlds,
/// My Assets, My Stories, My AI Agents, My Workflows, Portfolio, Archive.
/// Workspace menggunakan Asset Core yang sudah dibuat sebelumnya,
/// bukan database aset kedua yang terpisah.
/// Data bersumber dari [CreatorWorkspaceSection.values] dan state aktif dari
/// [creatorStudioProvider].
class CreatorWorkspaceScreen extends ConsumerWidget {
  const CreatorWorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSection = ref.watch(creatorStudioProvider).activeSection;
    const sections = CreatorWorkspaceSection.values;

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
                children: [
                  for (final s in sections)
                    _SectionCard(
                      section: s,
                      isActive: s == activeSection,
                      onTap: () => ref
                          .read(creatorStudioProvider.notifier)
                          .setSection(s),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.isActive,
    required this.onTap,
  });

  final CreatorWorkspaceSection section;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? context.palette.primary.withAlpha(51) // 20% opacity
        : context.palette.surface;

    return Card(
      color: color,
      elevation: isActive ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: context.palette.primary, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(VoidSpacing.md),
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
        ),
      ),
    );
  }
}
