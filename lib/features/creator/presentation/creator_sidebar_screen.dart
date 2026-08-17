import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 43.51 — Sidebar Upgrade.
///
/// Sidebar kreator dengan branding VOID SCRIPTOR dan navigasi utama:
/// Dashboard, Projects, AI Studio, Assets, Portfolio.
class CreatorSidebarScreen extends StatelessWidget {
  const CreatorSidebarScreen({super.key});

  static const items = <(String, IconData)>[
    ('Dashboard', Icons.dashboard_outlined),
    ('Projects', Icons.folder_copy_outlined),
    ('AI Studio', Icons.auto_awesome_outlined),
    ('Assets', Icons.inventory_2_outlined),
    ('Portfolio', Icons.work_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 240,
            color: context.palette.surface,
            padding: const EdgeInsets.all(VoidSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VOID SCRIPTOR',
                  style: VoidTypography.label.copyWith(
                    color: context.palette.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: VoidSpacing.lg),
                for (final (label, icon) in items)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: VoidSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 18, color: context.palette.primary),
                        const SizedBox(width: VoidSpacing.sm),
                        Text(
                          label,
                          style: VoidTypography.body.copyWith(
                            color: context.palette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: Container(color: context.palette.background)),
        ],
      ),
    );
  }
}
