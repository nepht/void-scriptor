import 'package:flutter/material.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 46.85 — World Health Dashboard.
///
/// Angka merupakan indikator internal dunia, bukan kualitas cerita.
class WorldHealthDashboardScreen extends StatelessWidget {
  const WorldHealthDashboardScreen({super.key});

  static const _metrics = <(String, int)>[
    ('Population', 82),
    ('Economy', 74),
    ('Stability', 61),
    ('Environment', 78),
    ('Conflict', 37),
    ('Resources', 54),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('World Health'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 700;
              return Wrap(
                spacing: VoidSpacing.md,
                runSpacing: VoidSpacing.md,
                children: [
                  for (final (label, value) in _metrics)
                    Container(
                      width: wide ? 200 : double.infinity,
                      padding: const EdgeInsets.all(VoidSpacing.md),
                      decoration: BoxDecoration(
                        color: context.palette.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: VoidTypography.caption.copyWith(
                              color: context.palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: VoidSpacing.xs),
                          Text(
                            '$value',
                            style: VoidTypography.headingLarge.copyWith(
                              color: context.palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: VoidSpacing.xs),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: value / 100,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
