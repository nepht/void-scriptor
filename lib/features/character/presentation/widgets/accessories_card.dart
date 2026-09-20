// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
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
        const Text(
          'Open Appearance & Gear to manage linked accessories.',
          style: VoidTypography.caption,
        ),
      ],
    ),
  );
}
