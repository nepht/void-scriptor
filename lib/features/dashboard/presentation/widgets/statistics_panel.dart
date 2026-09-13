import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
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
          const Text('Statistics', style: VoidTypography.headingMedium),
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
        _StatRow(label: 'Characters', value: '${snapshot.characters}'),
        _StatRow(label: 'Wardrobes', value: '${snapshot.wardrobes}'),
        _StatRow(label: 'Weapons', value: '${snapshot.weapons}'),
        _StatRow(label: 'Environments', value: '${snapshot.environments}'),
        _StatRow(label: 'Assets', value: '${snapshot.assets}'),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: VoidTypography.body)),
          Text(value, style: VoidTypography.title),
        ],
      ),
    );
  }
}
