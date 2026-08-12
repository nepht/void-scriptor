import 'package:flutter/material.dart';

import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class StatisticsPanel extends StatelessWidget {
  const StatisticsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const VoidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistics', style: VoidTypography.headingMedium),
          SizedBox(height: 14),
          _StatRow(label: 'Characters', value: '12'),
          _StatRow(label: 'Wardrobes', value: '27'),
          _StatRow(label: 'Weapons', value: '14'),
          _StatRow(label: 'Environments', value: '8'),
          _StatRow(label: 'Assets', value: '324'),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: VoidTypography.body)),
          Text(value, style: VoidTypography.title),
        ],
      ),
    );
  }
}
