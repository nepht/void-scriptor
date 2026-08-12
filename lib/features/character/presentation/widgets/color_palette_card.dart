// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import '../../../../design_system/colors/void_colors.dart';
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
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _Chip('Void Black', Color(0xFF050507)),
            _Chip('Void Violet', Color(0xFF5A2DFF)),
            _Chip('Radiant Purple', Color(0xFFA347FF)),
            _Chip('Electric Blue', Color(0xFF1E8DFF)),
            _Chip('Stellar White', Color(0xFFFFF8FF)),
          ],
        ),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: VoidColors.border),
      ),
    ),
  );
}
