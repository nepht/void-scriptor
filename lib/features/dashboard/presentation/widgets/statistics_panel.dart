import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';
import '../../application/dashboard_snapshot_provider.dart';
import '../../domain/dashboard_snapshot.dart';

class StatisticsPanel extends ConsumerWidget {
  const StatisticsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(dashboardSnapshotProvider);
    return VoidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_outlined,
                color: context.palette.primaryBright,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Statistics', style: VoidTypography.headingMedium),
              ),
              Text(
                'At a glance',
                style: VoidTypography.caption.copyWith(
                  color: context.palette.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          snapshot.when(
            data: (value) => value == null
                ? const Text(
                    'Open a project to calculate statistics.',
                    style: VoidTypography.body,
                  )
                : _MeasuredStatistics(snapshot: value),
            loading: () => const Text(
              'Calculating project statistics...',
              style: VoidTypography.body,
            ),
            error: (error, stack) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Project statistics are unavailable.',
                  style: VoidTypography.body,
                ),
                TextButton(
                  onPressed: () => ref.invalidate(dashboardSnapshotProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasuredStatistics extends StatelessWidget {
  const _MeasuredStatistics({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 280
                ? (constraints.maxWidth - 8) / 2
                : constraints.maxWidth;
            final metrics = [
              _MetricData(
                'Characters',
                snapshot.characters,
                Icons.people_alt_outlined,
              ),
              _MetricData(
                'Wardrobes',
                snapshot.wardrobes,
                Icons.checkroom_outlined,
              ),
              _MetricData('Weapons', snapshot.weapons, Icons.shield_outlined),
              _MetricData(
                'Environments',
                snapshot.environments,
                Icons.landscape_outlined,
              ),
              _MetricData('Assets', snapshot.assets, Icons.perm_media_outlined),
            ];
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final metric in metrics)
                  SizedBox(
                    width: width,
                    child: _MetricTile(metric: metric),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon);

  final String label;
  final int value;
  final IconData icon;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.borderSoft),
      ),
      child: Row(
        children: [
          Icon(metric.icon, size: 18, color: palette.primaryBright),
          const SizedBox(width: 8),
          Expanded(child: Text(metric.label, style: VoidTypography.caption)),
          Text('${metric.value}', style: VoidTypography.title),
        ],
      ),
    );
  }
}
