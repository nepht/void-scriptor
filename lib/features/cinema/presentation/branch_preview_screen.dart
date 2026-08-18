import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_scriptor/features/cinema/application/cinema_controller.dart';

import '../../../design_system/spacing/void_spacing.dart';
import '../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

/// Step 48.54 — Branch Preview.
///
/// Sebelum commit: tampilkan dampak tiap choice (Timeline Impact,
/// Relationship, Canon Risk).
class BranchPreviewScreen extends ConsumerWidget {
  const BranchPreviewScreen({super.key});

  static const _choices = <(String, String, String, String)>[
    ('Choice A', 'MEDIUM', '+24', 'LOW'),
    ('Choice B', 'HIGH', '-31', 'HIGH'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cinemaState = ref.watch(cinemaProvider);
    return Scaffold(
      key: ValueKey(cinemaState.isPlaying),
      appBar: AppBar(
        title: const Text('Branch Preview'),
        backgroundColor: context.palette.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VoidSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (name, impact, relation, risk) in _choices)
                _ChoiceCard(
                  name: name,
                  impact: impact,
                  relation: relation,
                  risk: risk,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.name,
    required this.impact,
    required this.relation,
    required this.risk,
  });

  final String name;
  final String impact;
  final String relation;
  final String risk;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.surface,
      margin: const EdgeInsets.only(bottom: VoidSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(VoidSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: VoidTypography.headingMedium.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: VoidSpacing.sm),
            _ImpactRow(label: 'Timeline Impact', value: impact),
            _ImpactRow(label: 'Relationship', value: relation),
            _ImpactRow(label: 'Canon Risk', value: risk),
          ],
        ),
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: VoidTypography.caption.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: VoidTypography.label.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
