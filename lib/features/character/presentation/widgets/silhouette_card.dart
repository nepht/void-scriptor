import 'package:flutter/material.dart';

import '../../../../design_system/theme/void_theme_context.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class SilhouetteCard extends StatelessWidget {
  const SilhouetteCard({super.key});

  @override
  Widget build(BuildContext context) => VoidCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Silhouette', style: VoidTypography.headingMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final label in const ['NEUTRAL', 'ACTION', 'COMBAT']) ...[
              if (label != 'NEUTRAL') const SizedBox(width: 6),
              Expanded(child: _SilhouetteSlot(label: label)),
            ],
          ],
        ),
      ],
    ),
  );
}

class _SilhouetteSlot extends StatelessWidget {
  const _SilhouetteSlot({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 150,
    decoration: BoxDecoration(
      color: context.palette.surfaceElevated,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: context.palette.borderSoft),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          label == 'COMBAT' ? Icons.bolt_outlined : Icons.accessibility_new,
          size: 46,
          color: context.palette.textDisabled,
        ),
        Positioned(
          left: 4,
          right: 4,
          bottom: 6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(child: Text(label, style: VoidTypography.caption)),
              FittedBox(
                child: Text(
                  'No image',
                  style: VoidTypography.caption.copyWith(
                    color: context.palette.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
