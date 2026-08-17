import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 43.6 — Dashboard Metrics.
///
/// Menampilkan 8 metrik: Active Projects, Published Works, Portfolio Views,
/// Followers, Collaborations, Asset Sales, AI Usage, Storage.
/// Untuk user pribadi, statistik sosial dapat disembunyikan.
class DashboardMetricsScreen extends StatelessWidget {
  const DashboardMetricsScreen({super.key, this.showSocialStats = true});

  final bool showSocialStats;

  @override
  Widget build(BuildContext context) {
    const metrics = <_Metric>[
      _Metric('Active Projects', '12', Icons.folder_copy_outlined),
      _Metric('Published Works', '3', Icons.public_outlined),
      _Metric('Portfolio Views', '1.2k', Icons.remove_red_eye_outlined),
      _Metric('Followers', '48', Icons.people_outline),
      _Metric('Collaborations', '2', Icons.group_work_outlined),
      _Metric('Asset Sales', '17', Icons.sell_outlined),
      _Metric('AI Usage', '86%', Icons.auto_awesome_outlined),
      _Metric('Storage', '1.8 GB', Icons.storage_outlined),
    ];

    final visible = showSocialStats
        ? metrics
        : metrics.where((m) => !_socialLabels.contains(m.label)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Metrics'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            final crossAxisCount = wide ? 4 : 2;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(VoidSpacing.lg),
              child: GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: VoidSpacing.md,
                crossAxisSpacing: VoidSpacing.md,
                childAspectRatio: wide ? 2.4 : 1.05,
                children: [
                  for (final m in visible) _MetricCard(metric: m, wide: wide),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

const _socialLabels = {'Followers', 'Collaborations', 'Portfolio Views'};

class _Metric {
  const _Metric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric, required this.wide});

  final _Metric metric;
  final bool wide;

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
            Icon(metric.icon, color: context.palette.primary, size: 18),
            const SizedBox(width: VoidSpacing.xs),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  style: VoidTypography.headingMedium.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                Text(
                  metric.label,
                  style: VoidTypography.caption.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
