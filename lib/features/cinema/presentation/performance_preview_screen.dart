import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_scriptor/features/cinema/application/cinema_controller.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 48.66 — Performance Preview.
///
/// Preview dapat mematikan: High Quality Hair, Heavy VFX, Ray Tracing,
/// High Resolution Shadows, Crowd Detail.
class PerformancePreviewScreen extends ConsumerWidget {
  const PerformancePreviewScreen({super.key});

  static const _toggles = <(String, IconData)>[
    ('High Quality Hair', Icons.face_outlined),
    ('Heavy VFX', Icons.auto_awesome_outlined),
    ('Ray Tracing', Icons.light_mode_outlined),
    ('High Resolution Shadows', Icons.dark_mode_outlined),
    ('Crowd Detail', Icons.groups_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cinemaState = ref.watch(cinemaProvider);
    return Scaffold(
      key: ValueKey(cinemaState.isPlaying),
      appBar: AppBar(
        title: const Text('Performance Preview'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Disable to boost preview performance:',
                style: VoidTypography.body.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(height: VoidSpacing.md),
              for (final (label, icon) in _toggles)
                Card(
                  color: context.palette.surface,
                  margin: const EdgeInsets.only(bottom: VoidSpacing.sm),
                  child: ListTile(
                    leading: Icon(icon, color: context.palette.primary),
                    title: Text(label),
                    trailing: Switch(value: false, onChanged: (_) {}),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
