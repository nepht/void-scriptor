import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 47.9 — Level Editor.
///
/// 3 panel: Assets (kiri), 3D World (tengah), Inspector (kanan) + Play.
class LevelEditorScreen extends StatelessWidget {
  const LevelEditorScreen({super.key});

  static const _assets = <(String, IconData)>[
    ('Character', Icons.person_outline),
    ('Weapon', Icons.gavel_outlined),
    ('Props', Icons.inventory_2_outlined),
    ('Environment', Icons.landscape_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Level Editor'),
        backgroundColor: context.palette.surface,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: VoidSpacing.md),
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Play'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            final assets = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (label, icon) in _assets)
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
                const _InspectorRow(label: 'Gameplay', value: 'Enabled'),
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
                          'Assets',
                          style: VoidTypography.headingMedium.copyWith(
                            color: context.palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: VoidSpacing.sm),
                        assets,
                      ],
                    ),
                  ),
                  const Expanded(child: _WorldView()),
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
                  'Assets',
                  style: VoidTypography.headingMedium.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: VoidSpacing.sm),
                assets,
                const SizedBox(height: VoidSpacing.lg),
                const _WorldView(),
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

class _WorldView extends StatelessWidget {
  const _WorldView();

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
          '3D World',
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
