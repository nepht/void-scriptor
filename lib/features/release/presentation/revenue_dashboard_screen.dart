import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 49.61 — Revenue Dashboard.
///
/// REVENUE per stream: Film, Games, Marketplace, Support,
/// Subscriptions, DLC.
class RevenueDashboardScreen extends StatelessWidget {
  const RevenueDashboardScreen({super.key});

  static const _streams = <(String, String)>[
    ('Film', '\$3,420'),
    ('Games', '\$5,910'),
    ('Marketplace', '\$1,240'),
    ('Support', '\$480'),
    ('Subscriptions', '\$2,150'),
    ('DLC', '\$890'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total',
                style: VoidTypography.caption.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
              Text(
                '\$14,090',
                style: VoidTypography.displayMedium.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: VoidSpacing.lg),
              for (final (label, value) in _streams)
                _RevenueRow(label: label, value: value),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  const _RevenueRow({required this.label, required this.value});

  final String label;
  final String value;

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
            value,
            style: VoidTypography.headingMedium.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
