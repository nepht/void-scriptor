import 'package:flutter/material.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class SilhouetteCard extends StatelessWidget {
  const SilhouetteCard({super.key});
  @override
  Widget build(BuildContext context) => VoidCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Silhouette', style: VoidTypography.headingMedium),
        const SizedBox(height: 14),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.palette.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.palette.borderSoft),
          ),
          child: Icon(
            Icons.accessibility_new,
            size: 64,
            color: context.palette.textDisabled,
          ),
        ),
      ],
    ),
  );
}
