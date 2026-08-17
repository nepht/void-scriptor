import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Sprint 43 — Step 43.5 Creator Dashboard.
///
/// Workspace `CREATOR` with dashboard sections.
/// Step 43.6 metrics are rendered by [CreatorDashboardScreen] using the
/// canonical metric set: Active Projects, Published Works, Portfolio Views,
/// Followers, Collaborations, Asset Sales, AI Usage, Storage.
class CreatorDashboardScreen extends StatelessWidget {
  const CreatorDashboardScreen({super.key});

  static const List<({String label, IconData icon})> _metrics = [
    (label: 'Active Projects', icon: Icons.folder_copy_outlined),
    (label: 'Published Works', icon: Icons.publish_outlined),
    (label: 'Portfolio Views', icon: Icons.visibility_outlined),
    (label: 'Followers', icon: Icons.people_alt_outlined),
    (label: 'Collaborations', icon: Icons.handshake_outlined),
    (label: 'Asset Sales', icon: Icons.sell_outlined),
    (label: 'AI Usage', icon: Icons.auto_awesome_outlined),
    (label: 'Storage', icon: Icons.storage_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(VoidSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CREATOR DASHBOARD',
                    style: VoidTypography.displayMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your public creator identity, portfolio and analytics.',
                    style: VoidTypography.body,
                  ),
                  const SizedBox(height: 28),
                  // Metrics grid — wraps on narrow, rows on wide.
                  Wrap(
                    spacing: VoidSpacing.md,
                    runSpacing: VoidSpacing.md,
                    children: [
                      for (final m in _metrics) _MetricCard(metric: m),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Recent Projects',
                    style: VoidTypography.headingMedium,
                  ),
                  const SizedBox(height: 12),
                  if (wide)
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          Expanded(child: _ProjectCard(index: i)),
                          if (i < 2) const SizedBox(width: VoidSpacing.md),
                        ],
                      ],
                    )
                  else
                    for (var i = 0; i < 3; i++) ...[
                      _ProjectCard(index: i),
                      const SizedBox(height: VoidSpacing.md),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final ({String label, IconData icon}) metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(VoidSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(metric.icon, color: context.palette.primaryBright),
          const SizedBox(width: 10),
          Flexible(child: Text(metric.label, style: VoidTypography.body)),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final name = switch (index) {
      0 => 'Project A',
      1 => 'Project B',
      _ => 'Project C',
    };
    return Container(
      padding: const EdgeInsets.all(VoidSpacing.lg),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.folder_open_outlined,
            color: context.palette.primaryBright,
          ),
          const SizedBox(height: 8),
          Text(name, style: VoidTypography.title),
        ],
      ),
    );
  }
}
