// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class ColorPaletteCard extends StatelessWidget {
  const ColorPaletteCard({super.key});
  @override
  Widget build(BuildContext context) => VoidCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Color Palette', style: VoidTypography.headingMedium),
        const SizedBox(height: 16),
        const Text(
          'No character palette saved. Use Primary References for color guidance.',
          style: VoidTypography.caption,
        ),
      ],
    ),
  );
}
