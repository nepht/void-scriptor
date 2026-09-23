import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../design_system/theme/void_theme_context.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class TurnaroundCard extends StatelessWidget {
  const TurnaroundCard({super.key, this.imagePaths = const {}});

  final Map<String, String> imagePaths;

  @override
  Widget build(BuildContext context) => VoidCard(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 440 ? 4 : 2;
        final grid = GridView.count(
          shrinkWrap: !constraints.hasBoundedHeight,
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Turnaround', style: VoidTypography.panelTitle),
            const SizedBox(height: 12),
            if (constraints.hasBoundedHeight) Expanded(child: grid) else grid,
          ],
        );
      },
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
        Expanded(child: _ReferenceImage(imagePath: imagePath)),
        Padding(
          padding: const EdgeInsets.all(7),
          child: Column(
            children: [
              Text(label, style: VoidTypography.smallPanelLabel),
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

class _ReferenceImage extends StatelessWidget {
  const _ReferenceImage({this.imagePath});
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path == null || !File(path).existsSync()) {
      return Center(
        child: Icon(
          Icons.accessibility_new,
          size: 38,
          color: context.palette.textDisabled,
        ),
      );
    }
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
      child: Image.file(
        File(path),
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: context.palette.textDisabled,
          ),
        ),
      ),
    );
  }
}
