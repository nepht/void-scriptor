import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 44.93 — Marketplace Home Final.
///
/// Home marketplace: Featured, Categories, Trending.
/// Mengikuti visual language aplikasi Void Scriptor.
class MarketplaceHomeScreen extends StatelessWidget {
  const MarketplaceHomeScreen({super.key});

  static const _categories = <(String, IconData)>[
    ('AI Agents', Icons.smart_toy_outlined),
    ('Workflows', Icons.account_tree_outlined),
    ('Prompts', Icons.auto_awesome_outlined),
    ('Templates', Icons.article_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Featured',
                style: VoidTypography.headingLarge.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: VoidSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(VoidSpacing.lg),
                decoration: BoxDecoration(
                  color: context.palette.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Featured Product',
                  style: VoidTypography.headingMedium.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: VoidSpacing.lg),
              Text(
                'Categories',
                style: VoidTypography.headingMedium.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: VoidSpacing.md),
              Wrap(
                spacing: VoidSpacing.sm,
                runSpacing: VoidSpacing.sm,
                children: [
                  for (final (label, icon) in _categories)
                    Chip(avatar: Icon(icon, size: 16), label: Text(label)),
                ],
              ),
              const SizedBox(height: VoidSpacing.lg),
              Text(
                'Trending',
                style: VoidTypography.headingMedium.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: VoidSpacing.md),
              const _ProductRow(name: 'Trending Agent', price: 'Free'),
              const _ProductRow(name: 'Popular Prompt Pack', price: '\$4.99'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.name, required this.price});

  final String name;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.surface,
      margin: const EdgeInsets.only(bottom: VoidSpacing.sm),
      child: ListTile(title: Text(name), trailing: Text(price)),
    );
  }
}
