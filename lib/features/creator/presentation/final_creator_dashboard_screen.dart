import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 43.59 — Final Creator Dashboard.
///
/// Layout desktop: sidebar (Dashboard, Projects, AI Studio, Assets) +
/// header "Welcome back" + tab metrics [Projects][Portfolio][Followers][Earnings].
class FinalCreatorDashboardScreen extends StatelessWidget {
  const FinalCreatorDashboardScreen({super.key});

  static const _sidebarItems = <(String, IconData)>[
    ('Dashboard', Icons.dashboard_outlined),
    ('Projects', Icons.folder_copy_outlined),
    ('AI Studio', Icons.auto_awesome_outlined),
    ('Assets', Icons.inventory_2_outlined),
    ('Portfolio', Icons.work_outline),
  ];

  static const _metricTabs = <String>[
    'Projects',
    'Portfolio',
    'Followers',
    'Earnings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Dashboard'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Sidebar(),
                  const Expanded(child: _DashboardContent()),
                ],
              );
            }
            return Column(
              children: [
                _Sidebar(horizontal: true),
                Expanded(child: _DashboardContent()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({this.horizontal = false});

  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final items = FinalCreatorDashboardScreen._sidebarItems
        .map((e) => _SidebarItem(label: e.$1, icon: e.$2))
        .toList();
    if (horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(VoidSpacing.sm),
        child: Row(children: items),
      );
    }
    return Container(
      width: 220,
      color: context.palette.surface,
      padding: const EdgeInsets.all(VoidSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VoidSpacing.xs),
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
    );
  }
}

class _DashboardContent extends StatelessWidget {
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
          const SizedBox(height: VoidSpacing.xs),
          Text(
            'Welcome back',
            style: VoidTypography.body.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: VoidSpacing.lg),
          Wrap(
            spacing: VoidSpacing.sm,
            runSpacing: VoidSpacing.sm,
            children: [
              for (final t in FinalCreatorDashboardScreen._metricTabs)
                _MetricTab(label: t),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTab extends StatelessWidget {
  const _MetricTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VoidSpacing.md,
        vertical: VoidSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: VoidTypography.label.copyWith(
          color: context.palette.textPrimary,
        ),
      ),
    );
  }
}
