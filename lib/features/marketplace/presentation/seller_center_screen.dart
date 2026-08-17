import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 44.30 — Seller Center.
///
/// Workspace penjual: Dashboard, Products, Revenue.
class SellerCenterScreen extends StatelessWidget {
  const SellerCenterScreen({super.key});

  static const _menuItems = <(String, IconData)>[
    ('Dashboard', Icons.dashboard_outlined),
    ('Products', Icons.inventory_2_outlined),
    ('Revenue', Icons.payments_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Center'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            final menu = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (label, icon) in _menuItems)
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
                    width: 220,
                    color: context.palette.surface,
                    padding: const EdgeInsets.all(VoidSpacing.md),
                    child: menu,
                  ),
                  const Expanded(child: _SellerDashboard()),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(VoidSpacing.md),
              children: [menu, const _SellerDashboard()],
            );
          },
        ),
      ),
    );
  }
}

class _SellerDashboard extends StatelessWidget {
  const _SellerDashboard();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VoidSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: VoidTypography.headingLarge.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: VoidSpacing.md),
          const Wrap(
            spacing: VoidSpacing.md,
            runSpacing: VoidSpacing.md,
            children: [
              _SellerStat(label: 'Sales', value: '42'),
              _SellerStat(label: 'Revenue', value: '\$128'),
              _SellerStat(label: 'Products', value: '12'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SellerStat extends StatelessWidget {
  const _SellerStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(VoidSpacing.md),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: VoidTypography.headingMedium.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
          Text(
            label,
            style: VoidTypography.caption.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
