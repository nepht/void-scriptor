// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import '../../../../design_system/colors/void_colors.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class AccessoriesCard extends StatelessWidget {
  const AccessoriesCard({super.key});
  @override
  Widget build(BuildContext context) => VoidCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Accessories', style: VoidTypography.headingMedium),
        const SizedBox(height: 14),
        const _Item(Icons.diamond_outlined, 'Necklace'),
        const _Item(Icons.circle_outlined, 'Bracelet'),
        const _Item(Icons.watch_outlined, 'Watch'),
      ],
    ),
  );
}

class _Item extends StatelessWidget {
  const _Item(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon, size: 17, color: VoidColors.textMuted),
        const SizedBox(width: 9),
        Text(label, style: VoidTypography.body),
      ],
    ),
  );
}
