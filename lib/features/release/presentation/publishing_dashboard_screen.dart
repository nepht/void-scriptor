import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 49.99 — Publishing Dashboard.
///
/// Publish: sidebar (Overview, Releases, ...) + konten + tombol
/// New Release.
class PublishingDashboardScreen extends StatelessWidget {
  const PublishingDashboardScreen({super.key});

  static const _menuItems = <(String, IconData)>[
    ('Overview', Icons.dashboard_outlined),
    ('Releases', Icons.rocket_launch_outlined),
    ('Revenue', Icons.payments_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publish'),
        backgroundColor: context.palette.surface,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: VoidSpacing.md),
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Release'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
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
                    width: 200,
                    color: context.palette.surface,
                    padding: const EdgeInsets.all(VoidSpacing.md),
                    child: menu,
                  ),
                  const Expanded(child: _ThisMonth()),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(VoidSpacing.md),
              children: [menu, const _ThisMonth()],
            );
          },
        ),
      ),
    );
  }
}

class _ThisMonth extends StatelessWidget {
  const _ThisMonth();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VoidSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: VoidTypography.headingLarge.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: VoidSpacing.md),
          const _StatCard(label: 'Active Releases', value: '4'),
          const _StatCard(label: 'Total Views', value: '2.4k'),
          const _StatCard(label: 'Revenue', value: '\$14,090'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.surface,
      margin: const EdgeInsets.only(bottom: VoidSpacing.sm),
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: VoidTypography.headingMedium.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
      ),
    );
  }
}
