import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 48.115 — Cinema Workspace.
///
/// Layout 3 panel: PROJECT (kiri), viewport (tengah), detail (kanan),
/// dengan tombol Preview dan Render di top bar.
class CinemaWorkspaceScreen extends StatelessWidget {
  const CinemaWorkspaceScreen({super.key});

  static const _projectItems = <(String, IconData)>[
    ('Shots', Icons.movie_outlined),
    ('Sequences', Icons.view_carousel_outlined),
    ('Timeline', Icons.timeline_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cinema'),
        backgroundColor: context.palette.surface,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: VoidSpacing.sm),
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Preview'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: VoidSpacing.md),
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.movie_filter_outlined, size: 18),
              label: const Text('Render'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            final project = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (label, icon) in _projectItems)
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
                          'Project',
                          style: VoidTypography.headingMedium.copyWith(
                            color: context.palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: VoidSpacing.sm),
                        project,
                      ],
                    ),
                  ),
                  const Expanded(child: _Viewport()),
                  Container(
                    width: 220,
                    color: context.palette.surface,
                    padding: const EdgeInsets.all(VoidSpacing.md),
                    child: const _DetailPanel(),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(VoidSpacing.md),
              children: [
                Text(
                  'Project',
                  style: VoidTypography.headingMedium.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: VoidSpacing.sm),
                project,
                const SizedBox(height: VoidSpacing.lg),
                const _Viewport(),
                const SizedBox(height: VoidSpacing.lg),
                const _DetailPanel(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Viewport extends StatelessWidget {
  const _Viewport();

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
          'Viewport',
          style: VoidTypography.headingMedium.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shot Details',
          style: VoidTypography.headingMedium.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        const SizedBox(height: VoidSpacing.md),
        Text(
          'Selected: Shot 001',
          style: VoidTypography.body.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
      ],
    );
  }
}
