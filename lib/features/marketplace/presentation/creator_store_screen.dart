import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 44.29 — Creator Store.
///
/// Setiap creator mempunyai store: Products, Followers, Rating.
/// Terhubung dengan Creator Profile (Sprint 43).
class CreatorStoreScreen extends StatelessWidget {
  const CreatorStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Store'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Creator Name',
                style: VoidTypography.headingLarge.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: VoidSpacing.md),
              const Row(
                children: [
                  _StatBadge(label: 'Products', value: '12'),
                  SizedBox(width: VoidSpacing.sm),
                  _StatBadge(label: 'Followers', value: '1.2k'),
                  SizedBox(width: VoidSpacing.sm),
                  _StatBadge(label: 'Rating', value: '4.9'),
                ],
              ),
              const SizedBox(height: VoidSpacing.lg),
              Text(
                'Products',
                style: VoidTypography.headingMedium.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: VoidSpacing.sm),
              const _ProductTile(name: 'Sample Product', price: 'Free'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(VoidSpacing.sm),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
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
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.name, required this.price});

  final String name;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.surface,
      child: ListTile(
        leading: const Icon(Icons.inventory_2_outlined),
        title: Text(name),
        trailing: Text(price),
      ),
    );
  }
}
