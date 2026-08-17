import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Sprint 43 — Step 43.33 Donation UI screen.
///
/// Lets patrons support a creator with one-time tips or subscriptions
/// (domain: PaymentProvider, S43.31–43.33).
class DonationScreen extends StatelessWidget {
  const DonationScreen({super.key});

  static const List<({String label, IconData icon})> _options = [
    (label: 'One-time', icon: Icons.volunteer_activism_outlined),
    (label: 'Subscription', icon: Icons.repeat_outlined),
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
                  const Text('DONATIONS', style: VoidTypography.displayMedium),
                  const SizedBox(height: 6),
                  const Text('Support the Creator', style: VoidTypography.body),
                  const SizedBox(height: 28),
                  if (wide)
                    Wrap(
                      spacing: VoidSpacing.md,
                      runSpacing: VoidSpacing.md,
                      children: [
                        for (final o in _options) _DonateCard(option: o),
                      ],
                    )
                  else
                    for (final o in _options) ...[
                      _DonateCard(option: o),
                      const SizedBox(height: VoidSpacing.md),
                    ],
                  const SizedBox(height: 28),
                  const _SectionTitle('Recent Donations'),
                  const SizedBox(height: 12),
                  const _InfoRow(
                    label: 'Last Donation',
                    value: 'Rp 150.000',
                    icon: Icons.history_outlined,
                  ),
                  const SizedBox(height: VoidSpacing.sm),
                  const _InfoRow(
                    label: 'Total Received',
                    value: 'Rp 2.450.000',
                    icon: Icons.account_balance_wallet_outlined,
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

class _DonateCard extends StatelessWidget {
  const _DonateCard({required this.option});

  final ({String label, IconData icon}) option;

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
          Icon(option.icon, color: context.palette.primaryBright),
          const SizedBox(width: 10),
          Flexible(child: Text(option.label, style: VoidTypography.body)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: VoidTypography.headingMedium);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

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
          Icon(icon, color: context.palette.primaryBright),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: VoidTypography.body)),
          const SizedBox(width: 16),
          Text(value, style: VoidTypography.title),
        ],
      ),
    );
  }
}
