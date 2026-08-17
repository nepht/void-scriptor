import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 48.49 — Animatic Preview.
///
/// User dapat memeriksa: Pacing, Shot Duration, Dialogue Timing,
/// Camera Rhythm, Scene Length.
class AnimaticPreviewScreen extends StatelessWidget {
  const AnimaticPreviewScreen({super.key});

  static const _metrics = <(String, String)>[
    ('Pacing', 'Balanced'),
    ('Shot Duration', '3.2s avg'),
    ('Dialogue Timing', 'On beat'),
    ('Camera Rhythm', 'Smooth'),
    ('Scene Length', '48s'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animatic Preview'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (label, value) in _metrics)
                _MetricRow(label: label, value: value),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VoidSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 140,
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
