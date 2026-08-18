import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_scriptor/features/platform/application/platform_controller.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 50.118 — Optional Tour.
///
/// Tour: Dashboard, Projects, Character, AI Studio, Publish.
class OptionalTourScreen extends ConsumerWidget {
  const OptionalTourScreen({super.key});

  static const _stops = <(String, IconData)>[
    ('Dashboard', Icons.dashboard_outlined),
    ('Projects', Icons.folder_outlined),
    ('Character', Icons.person_outline),
    ('AI Studio', Icons.auto_awesome_outlined),
    ('Publish', Icons.rocket_launch_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(platformProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore Void Scriptor',
                style: VoidTypography.headingLarge.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: VoidSpacing.md),
              for (final (label, icon) in _stops)
                _TourStop(label: label, icon: icon),
              const SizedBox(height: VoidSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Start Tour'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TourStop extends StatelessWidget {
  const _TourStop({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.surface,
      margin: const EdgeInsets.only(bottom: VoidSpacing.sm),
      child: ListTile(
        leading: Icon(icon, color: context.palette.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
