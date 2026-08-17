import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 44.2 — Marketplace Workspace.
///
/// Menu utama marketplace: Discover, AI Agents, Workflows, Prompts,
/// Templates, My Library. Layout desktop: sidebar + konten.
class MarketplaceWorkspaceScreen extends StatelessWidget {
  const MarketplaceWorkspaceScreen({super.key});

  static const _menuItems = <(String, IconData)>[
    ('Discover', Icons.explore_outlined),
    ('AI Agents', Icons.smart_toy_outlined),
    ('Workflows', Icons.account_tree_outlined),
    ('Prompts', Icons.auto_awesome_outlined),
    ('Templates', Icons.article_outlined),
    ('My Library', Icons.library_books_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final items = [
              for (final (label, icon) in _menuItems)
                _MenuRow(label: label, icon: icon),
            ];
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 240,
                    color: context.palette.surface,
                    padding: const EdgeInsets.all(VoidSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: items,
                    ),
                  ),
                  Expanded(child: _HomePlaceholder()),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(VoidSpacing.md),
              children: items,
            );
          },
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VoidSpacing.sm),
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

class _HomePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Discover',
        style: VoidTypography.headingLarge.copyWith(
          color: context.palette.textPrimary,
        ),
      ),
    );
  }
}
