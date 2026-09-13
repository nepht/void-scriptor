import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class CharacterPortraitCard extends StatelessWidget {
  const CharacterPortraitCard({super.key, this.imagePath, this.onAddPortrait});
  final String? imagePath;

  /// Bound production action that imports a local image into the project
  /// package. Null keeps the honest guidance snackbar instead of a silent
  /// no-op button.
  final Future<void> Function()? onAddPortrait;
  @override
  Widget build(BuildContext context) => VoidCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Portrait', style: VoidTypography.headingMedium),
        const SizedBox(height: 14),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: context.palette.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.palette.borderSoft),
            ),
            child: imagePath == null || !File(imagePath!).existsSync()
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 42,
                          color: context.palette.textMuted,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No portrait',
                          style: VoidTypography.caption,
                        ),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(imagePath!), fit: BoxFit.cover),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed:
                onAddPortrait ??
                () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Portrait upload is available from the project asset folder.',
                    ),
                  ),
                ),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Add Portrait'),
          ),
        ),
      ],
    ),
  );
}
