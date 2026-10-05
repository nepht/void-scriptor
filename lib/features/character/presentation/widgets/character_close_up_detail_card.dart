import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../design_system/theme/void_theme_context.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class CharacterCloseUpDetailCard extends StatelessWidget {
  const CharacterCloseUpDetailCard({super.key, this.imagePaths = const []});

  final List<String> imagePaths;

  @override
  Widget build(BuildContext context) => VoidCard(
    child: LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CLOSE UP DETAIL', style: VoidTypography.panelTitle),
          const SizedBox(height: 10),
          if (constraints.hasBoundedHeight)
            Expanded(child: _DetailStrip(imagePaths: imagePaths))
          else
            SizedBox(height: 104, child: _DetailStrip(imagePaths: imagePaths)),
          if (imagePaths.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'No close-up references linked.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VoidTypography.caption.copyWith(
                color: context.palette.textMuted,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _DetailStrip extends StatelessWidget {
  const _DetailStrip({required this.imagePaths});
  final List<String> imagePaths;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var index = 0; index < 4; index++) ...[
        if (index > 0) const SizedBox(width: 5),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: context.palette.surfaceElevated,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: context.palette.borderSoft),
            ),
            child: _DetailImage(
              path: index < imagePaths.length ? imagePaths[index] : null,
              placeholder: const [
                Icons.face_outlined,
                Icons.checkroom_outlined,
                Icons.hexagon_outlined,
                Icons.auto_awesome_outlined,
              ][index],
            ),
          ),
        ),
      ],
    ],
  );
}

class _DetailImage extends StatelessWidget {
  const _DetailImage({required this.path, required this.placeholder});
  final String? path;
  final IconData placeholder;

  @override
  Widget build(BuildContext context) {
    final imagePath = path;
    if (imagePath == null || !File(imagePath).existsSync()) {
      return Center(
        child: Icon(placeholder, color: context.palette.textDisabled),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: context.palette.textDisabled,
          ),
        ),
      ),
    );
  }
}
