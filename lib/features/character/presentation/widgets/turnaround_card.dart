import 'package:flutter/material.dart';

import '../../../../design_system/theme/void_theme_context.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class TurnaroundCard extends StatelessWidget {
  const TurnaroundCard({super.key, this.imagePaths = const {}});

  final Map<String, String> imagePaths;

  @override
  Widget build(BuildContext context) => VoidCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Turnaround', style: VoidTypography.headingMedium),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 440 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: .62,
              children: [
                for (final label in const [
                  'FRONT VIEW',
                  'SIDE VIEW',
                  'BACK VIEW',
                  '3/4 VIEW',
                ])
                  _ReferenceSlot(label: label, imagePath: imagePaths[label]),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _ReferenceSlot extends StatelessWidget {
  const _ReferenceSlot({required this.label, this.imagePath});

  final String label;
  final String? imagePath;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.palette.surfaceElevated,
      border: Border.all(color: context.palette.borderSoft),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      children: [
        Expanded(
          child: Center(
            child: Icon(
              Icons.accessibility_new,
              size: 38,
              color: context.palette.textDisabled,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(7),
          child: Column(
            children: [
              Text(label, style: VoidTypography.caption),
              if (imagePath == null)
                Text(
                  'No image',
                  style: VoidTypography.caption.copyWith(
                    color: context.palette.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
