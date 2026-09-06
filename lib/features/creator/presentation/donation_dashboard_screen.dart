import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Sprint 43 — Step 43.34 Donation Dashboard screen.
///
/// Shows monthly goal progress and top supporters for a creator.
class DonationDashboardScreen extends StatelessWidget {
  const DonationDashboardScreen({super.key});

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
                    'DONATION DASHBOARD',
                    style: VoidTypography.displayMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Payments not connected',
                    style: VoidTypography.body,
                  ),
                  const SizedBox(height: 28),
                  if (wide)
                    const Row(
                      children: [
                        Expanded(
                          child: _GoalCard(
                            label: 'Monthly Goal',
                            value: 'Not available',
                          ),
                        ),
                        SizedBox(width: VoidSpacing.md),
                        Expanded(
                          child: _GoalCard(
                            label: 'Supporters',
                            value: '0 verified',
                          ),
                        ),
                      ],
                    )
                  else ...[
                    const _GoalCard(
                      label: 'Monthly Goal',
                      value: 'Not available',
                    ),
                    const SizedBox(height: VoidSpacing.md),
                    const _GoalCard(label: 'Supporters', value: '0 verified'),
                  ],
                  const SizedBox(height: 28),
                  const Text(
                    'Top Supporters',
                    style: VoidTypography.headingMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No verified supporters yet.',
                    style: VoidTypography.body,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoidSpacing.lg),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: VoidTypography.headingMedium),
          const SizedBox(height: 8),
          Text(value, style: VoidTypography.title),
        ],
      ),
    );
  }
}
