import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 45.82 — Multiverse Workspace.
///
/// Sidebar multiverse: Universes, Timelines, Crossovers, Portability.
class MultiverseWorkspaceScreen extends StatelessWidget {
  const MultiverseWorkspaceScreen({super.key});

  static const _menuItems = <(String, IconData)>[
    ('Universes', Icons.public_outlined),
    ('Timelines', Icons.timeline_outlined),
    ('Crossovers', Icons.swap_horiz_outlined),
    ('Portability', Icons.swap_vert_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiverse'),
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
                    width: 220,
                    color: context.palette.surface,
                    padding: const EdgeInsets.all(VoidSpacing.md),
                    child: menu,
                  ),
                  const Expanded(child: _UniverseList()),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(VoidSpacing.md),
              children: [menu, const _UniverseList()],
            );
          },
        ),
      ),
    );
  }
}

class _UniverseList extends StatelessWidget {
  const _UniverseList();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VoidSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Universes',
            style: VoidTypography.headingLarge.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: VoidSpacing.md),
          const _UniverseTile(name: 'Primary Canon', type: 'Canon'),
          const _UniverseTile(name: 'Alternate Timeline', type: 'Branch'),
        ],
      ),
    );
  }
}

class _UniverseTile extends StatelessWidget {
  const _UniverseTile({required this.name, required this.type});

  final String name;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.surface,
      margin: const EdgeInsets.only(bottom: VoidSpacing.sm),
      child: ListTile(
        leading: const Icon(Icons.public_outlined),
        title: Text(name),
        subtitle: Text(type),
      ),
    );
  }
}
