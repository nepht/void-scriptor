import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../design_system/theme/void_theme_context.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class CharacterPortraitCard extends StatelessWidget {
  const CharacterPortraitCard({
    super.key,
    this.imagePath,
    this.onAddPortrait,
    this.onExport,
    this.onEdit,
    this.onExpand,
  });

  final String? imagePath;
  final Future<void> Function()? onAddPortrait;
  final VoidCallback? onExport;
  final VoidCallback? onEdit;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) => VoidCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('MAIN PORTRAIT', style: VoidTypography.headingMedium),
            ),
            _ToolbarButton(
              tooltip: onExport == null ? 'Export (coming soon)' : 'Export',
              icon: Icons.download_outlined,
              onPressed: onExport,
            ),
            _ToolbarButton(
              tooltip: onEdit == null ? 'Edit (coming soon)' : 'Edit',
              icon: Icons.edit_outlined,
              onPressed: onEdit,
            ),
            _ToolbarButton(
              tooltip: onExpand == null ? 'Expand (coming soon)' : 'Expand',
              icon: Icons.open_in_full_outlined,
              onPressed: onExpand,
            ),
          ],
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: context.palette.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.palette.borderSoft),
            ),
            child: imagePath == null || !File(imagePath!).existsSync()
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 48,
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
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(imagePath!),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) => const Center(
                        child: Text(
                          'Image unavailable. Import a new portrait.',
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
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
            label: Text(
              imagePath == null ? 'Add Portrait' : 'Replace Portrait',
            ),
          ),
        ),
      ],
    ),
  );
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.tooltip,
    required this.icon,
    this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    onPressed: onPressed,
    icon: Icon(icon, size: 17),
  );
}
