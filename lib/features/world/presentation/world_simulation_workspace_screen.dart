import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 46.88 — World Simulation Workspace.
///
/// Workspace simulasi: sidebar (Overview, Population, Economy, ...),
/// world map, playback control (Day 421, 100x).
class WorldSimulationWorkspaceScreen extends StatelessWidget {
  const WorldSimulationWorkspaceScreen({super.key});

  static const _menuItems = <(String, IconData)>[
    ('Overview', Icons.dashboard_outlined),
    ('Population', Icons.groups_outlined),
    ('Economy', Icons.trending_up_outlined),
    ('Factions', Icons.flag_outlined),
    ('Events', Icons.event_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('World Simulation'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final menu = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (label, icon) in _menuItems)
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
            );
            final playback = Row(
              children: [
                const Icon(Icons.play_circle_outline, size: 20),
                const SizedBox(width: VoidSpacing.sm),
                Text(
                  'Day 421',
                  style: VoidTypography.caption.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '100x',
                  style: VoidTypography.caption.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
              ],
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 200,
                    color: context.palette.surface,
                    padding: const EdgeInsets.all(VoidSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        menu,
                        const SizedBox(height: VoidSpacing.lg),
                        playback,
                      ],
                    ),
                  ),
                  const Expanded(child: _WorldMap()),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(VoidSpacing.md),
              children: [
                menu,
                const SizedBox(height: VoidSpacing.md),
                playback,
                const SizedBox(height: VoidSpacing.md),
                const _WorldMap(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WorldMap extends StatelessWidget {
  const _WorldMap();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(VoidSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.borderSoft),
      ),
      child: Center(
        child: Text(
          'World Map',
          style: VoidTypography.headingMedium.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
      ),
    );
  }
}
