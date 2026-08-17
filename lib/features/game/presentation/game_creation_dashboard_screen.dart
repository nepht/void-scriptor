import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 47.115 — Game Creation Dashboard.
///
/// Layout: sidebar WORLD (Levels, Characters) + GAME WORLD + INSPECTOR,
/// dengan tombol Play dan Build.
class GameCreationDashboardScreen extends StatelessWidget {
  const GameCreationDashboardScreen({super.key});

  static const _worldItems = <(String, IconData)>[
    ('Levels', Icons.layers_outlined),
    ('Characters', Icons.person_outline),
    ('Quests', Icons.flag_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game'),
        backgroundColor: context.palette.surface,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: VoidSpacing.sm),
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Play'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: VoidSpacing.md),
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.build_outlined, size: 18),
              label: const Text('Build'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            final world = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (label, icon) in _worldItems)
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
            final inspector = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inspector',
                  style: VoidTypography.headingMedium.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: VoidSpacing.md),
                const _InspectorRow(
                  label: 'Transform',
                  value: 'X: 0 Y: 0 Z: 0',
                ),
              ],
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 180,
                    color: context.palette.surface,
                    padding: const EdgeInsets.all(VoidSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'World',
                          style: VoidTypography.headingMedium.copyWith(
                            color: context.palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: VoidSpacing.sm),
                        world,
                      ],
                    ),
                  ),
                  const Expanded(child: _GameWorld()),
                  Container(
                    width: 220,
                    color: context.palette.surface,
                    padding: const EdgeInsets.all(VoidSpacing.md),
                    child: inspector,
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(VoidSpacing.md),
              children: [
                Text(
                  'World',
                  style: VoidTypography.headingMedium.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: VoidSpacing.sm),
                world,
                const SizedBox(height: VoidSpacing.lg),
                const _GameWorld(),
                const SizedBox(height: VoidSpacing.lg),
                inspector,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GameWorld extends StatelessWidget {
  const _GameWorld();

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
          'Game World',
          style: VoidTypography.headingMedium.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _InspectorRow extends StatelessWidget {
  const _InspectorRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VoidSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: VoidTypography.caption.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: VoidTypography.caption.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
