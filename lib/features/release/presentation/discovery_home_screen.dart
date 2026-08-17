import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 49.44 — Discovery Home.
///
/// Featured, New Releases, Trending, Recommended, Games, Films,
/// Interactive, Creators, Universes.
class DiscoveryHomeScreen extends StatelessWidget {
  const DiscoveryHomeScreen({super.key});

  static const _categories = <String>[
    'Games',
    'Films',
    'Interactive',
    'Creators',
    'Universes',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(title: 'Featured'),
              const SizedBox(height: VoidSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(VoidSpacing.lg),
                decoration: BoxDecoration(
                  color: context.palette.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Featured Release',
                  style: VoidTypography.headingMedium.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: VoidSpacing.lg),
              const _SectionHeader(title: 'New Releases'),
              const SizedBox(height: VoidSpacing.md),
              const _ReleaseCard(title: 'New Release 1', type: 'Game'),
              const _ReleaseCard(title: 'New Release 2', type: 'Film'),
              const SizedBox(height: VoidSpacing.lg),
              const _SectionHeader(title: 'Trending'),
              const SizedBox(height: VoidSpacing.md),
              Wrap(
                spacing: VoidSpacing.sm,
                runSpacing: VoidSpacing.sm,
                children: [for (final c in _categories) Chip(label: Text(c))],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: VoidTypography.headingMedium.copyWith(
        color: context.palette.textPrimary,
      ),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({required this.title, required this.type});

  final String title;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.surface,
      margin: const EdgeInsets.only(bottom: VoidSpacing.sm),
      child: ListTile(
        leading: Icon(
          type == 'Game' ? Icons.sports_esports_outlined : Icons.movie_outlined,
          color: context.palette.primary,
        ),
        title: Text(title),
        subtitle: Text(type),
      ),
    );
  }
}
