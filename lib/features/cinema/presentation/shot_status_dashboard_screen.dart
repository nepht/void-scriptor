import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 48.85 — Shot Status Dashboard.
///
/// TOTAL SHOTS 214 — Approved 126, Review 31, In Progress 42, Blocked 15.
class ShotStatusDashboardScreen extends ConsumerWidget {
  const ShotStatusDashboardScreen({super.key});

  static const _statuses = <(String, int)>[
    ('Approved', 126),
    ('Review', 31),
    ('In Progress', 42),
    ('Blocked', 15),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final cinemaState = ref.watch(cinemaProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shot Status'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Shots',
                style: VoidTypography.caption.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
              Text(
                '214',
                style: VoidTypography.displayMedium.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: VoidSpacing.lg),
              for (final (label, count) in _statuses)
                _StatusRow(label: label, count: count),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VoidSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: VoidTypography.body.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
          ),
          Text(
            '$count',
            style: VoidTypography.headingMedium.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
