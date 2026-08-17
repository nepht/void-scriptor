import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 46.89 — Simulation Inspector.
///
/// Klik lokasi (mis. Neo Megacity) → detail: Population, Economy,
/// Stability, Weather, Threat, Active Events.
class SimulationInspectorScreen extends StatelessWidget {
  const SimulationInspectorScreen({super.key});

  static const _stats = <(String, String)>[
    ('Population', '18.2M'),
    ('Economy', 'Growing'),
    ('Stability', '71%'),
    ('Weather', 'Cloudy'),
    ('Threat', 'Moderate'),
    ('Active Events', '7'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulation Inspector'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Neo Megacity',
                style: VoidTypography.headingLarge.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: VoidSpacing.md),
              for (final (label, value) in _stats)
                _StatRow(label: label, value: value),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VoidSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 120,
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
