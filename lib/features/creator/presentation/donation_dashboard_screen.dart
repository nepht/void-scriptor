import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Sprint 43 — Step 43.34 Donation Dashboard screen.
///
/// Shows monthly goal progress and top supporters for a creator.
class DonationDashboardScreen extends StatelessWidget {
  const DonationDashboardScreen({super.key});

  static const List<({String name, String amount})> _supporters = [
    (name: 'VoidKnight', amount: 'Rp 500.000'),
    (name: 'Sari', amount: 'Rp 250.000'),
    (name: 'Bayu', amount: 'Rp 100.000'),
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
                    'DONATION DASHBOARD',
                    style: VoidTypography.displayMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Monitor patron support and monthly goals.',
                    style: VoidTypography.body,
                  ),
                  const SizedBox(height: 28),
                  if (wide)
                    Row(
                      children: [
                        Expanded(
                          child: const _GoalCard(
                            label: 'Monthly Goal',
                            value: 'Rp 2.450.000 / Rp 5.000.000',
                          ),
                        ),
                        const SizedBox(width: VoidSpacing.md),
                        Expanded(
                          child: const _GoalCard(
                            label: 'Supporters',
                            value: '32 patrons',
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _GoalCard(
                      label: 'Monthly Goal',
                      value: 'Rp 2.450.000 / Rp 5.000.000',
                    ),
                    const SizedBox(height: VoidSpacing.md),
                    _GoalCard(label: 'Supporters', value: '32 patrons'),
                  ],
                  const SizedBox(height: 28),
                  const Text(
                    'Top Supporters',
                    style: VoidTypography.headingMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final s in _supporters) ...[
                    _SupporterRow(name: s.name, amount: s.amount),
                    const SizedBox(height: VoidSpacing.sm),
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

class _SupporterRow extends StatelessWidget {
  const _SupporterRow({required this.name, required this.amount});

  final String name;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoidSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, color: context.palette.primaryBright),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: VoidTypography.body)),
          Text(amount, style: VoidTypography.title),
        ],
      ),
    );
  }
}
