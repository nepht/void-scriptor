import 'package:flutter/material.dart';

import '../../../../design_system/theme/void_theme_context.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class CharacterPaletteEntry {
  const CharacterPaletteEntry(this.label, this.color, this.hex);
  final String label;
  final Color color;
  final String hex;
}

class ColorPaletteCard extends StatelessWidget {
  const ColorPaletteCard({super.key, this.entries = const []});

  final List<CharacterPaletteEntry> entries;

  @override
  Widget build(BuildContext context) => VoidCard(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final body = entries.isEmpty
            ? const _EmptyPalette()
            : constraints.hasBoundedHeight
            ? ListView(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final entry in entries) _PaletteRow(entry: entry),
                ],
              )
            : Column(
                children: [
                  for (final entry in entries) _PaletteRow(entry: entry),
                ],
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Color Palette', style: VoidTypography.headingMedium),
            const SizedBox(height: 12),
            if (constraints.hasBoundedHeight) Expanded(child: body) else body,
          ],
        );
      },
    ),
  );
}

class _EmptyPalette extends StatelessWidget {
  const _EmptyPalette();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.palette.surfaceElevated,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: context.palette.borderSoft),
    ),
    child: const Text(
      'No palette saved\nUse Primary References for color guidance.',
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: VoidTypography.caption,
    ),
  );
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({required this.entry});
  final CharacterPaletteEntry entry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 18,
          decoration: BoxDecoration(
            color: entry.color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: context.palette.borderSoft),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(entry.label, style: VoidTypography.caption)),
        Text(entry.hex, style: VoidTypography.caption),
      ],
    ),
  );
}
