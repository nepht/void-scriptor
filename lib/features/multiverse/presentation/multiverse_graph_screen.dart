import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 45.83 — Multiverse Graph UI.
///
/// Visualisasi interaktif graph multiverse dengan kontrol Zoom.
class MultiverseGraphScreen extends StatelessWidget {
  const MultiverseGraphScreen({super.key});

  static const _nodes = <String>[
    'Primary Canon',
    'Alpha Branch',
    'Omega Branch',
    'Crossover Hub',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiverse Graph'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(VoidSpacing.md),
              child: Row(
                children: [
                  Text(
                    'Zoom',
                    style: VoidTypography.label.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                  const SizedBox(width: VoidSpacing.sm),
                  const Icon(Icons.zoom_out),
                  Expanded(child: Slider(value: 1.0, onChanged: (_) {})),
                  const Icon(Icons.zoom_in),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: VoidSpacing.md,
                  runSpacing: VoidSpacing.md,
                  alignment: WrapAlignment.center,
                  children: [for (final n in _nodes) _GraphNode(label: n)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphNode extends StatelessWidget {
  const _GraphNode({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VoidSpacing.md,
        vertical: VoidSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.palette.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.primary),
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
