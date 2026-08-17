import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 49.3 — Publishing Workspace.
///
/// Workspace Publish: Overview, Releases, Platforms.
class PublishingWorkspaceScreen extends StatelessWidget {
  const PublishingWorkspaceScreen({super.key});

  static const _menuItems = <(String, IconData)>[
    ('Overview', Icons.dashboard_outlined),
    ('Releases', Icons.rocket_launch_outlined),
    ('Platforms', Icons.devices_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publish'),
        backgroundColor: context.palette.surface,
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
                  const Expanded(child: _ReleaseList()),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(VoidSpacing.md),
              children: [menu, const _ReleaseList()],
            );
          },
        ),
      ),
    );
  }
}

class _ReleaseList extends StatelessWidget {
  const _ReleaseList();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VoidSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Releases',
            style: VoidTypography.headingLarge.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: VoidSpacing.md),
          const _ReleaseTile(title: 'Void Saga Vol. 1', status: 'Live'),
          const _ReleaseTile(title: 'Void Saga Vol. 2', status: 'In Review'),
        ],
      ),
    );
  }
}

class _ReleaseTile extends StatelessWidget {
  const _ReleaseTile({required this.title, required this.status});

  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.surface,
      margin: const EdgeInsets.only(bottom: VoidSpacing.sm),
      child: ListTile(
        leading: const Icon(Icons.rocket_launch_outlined),
        title: Text(title),
        subtitle: Text(status),
      ),
    );
  }
}
