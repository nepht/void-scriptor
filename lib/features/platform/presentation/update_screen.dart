import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_scriptor/features/platform/application/platform_controller.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 50.60 — Update UI.
///
/// Void Scriptor 1.0.1 available.
/// Download: 124 MB — Includes: Crash fixes, Timeline performance.
/// [Later] [Download].
class UpdateScreen extends ConsumerWidget {
  const UpdateScreen({super.key});

  static const _notes = <String>[
    'Crash fixes',
    'Timeline performance improvements',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(platformProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Void Scriptor 1.0.1 available.',
                style: VoidTypography.headingMedium.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: VoidSpacing.md),
              const _InfoRow(label: 'Download', value: '124 MB'),
              const SizedBox(height: VoidSpacing.md),
              Text(
                'Includes:',
                style: VoidTypography.label.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(height: VoidSpacing.xs),
              for (final n in _notes)
                Text(
                  '• $n',
                  style: VoidTypography.body.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
              const SizedBox(height: VoidSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('Later'),
                    ),
                  ),
                  const SizedBox(width: VoidSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {},
                      child: const Text('Download'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VoidSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: VoidTypography.label.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: VoidTypography.body.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
