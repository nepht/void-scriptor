import 'package:flutter/material.dart';

import '../../../../design_system/theme/void_theme_context.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class CharacterAccessoryEntry {
  const CharacterAccessoryEntry(this.label, this.description);
  final String label;
  final String description;
}

class AccessoriesCard extends StatelessWidget {
  const AccessoriesCard({super.key, this.entries = const []});

  final List<CharacterAccessoryEntry> entries;

  @override
  Widget build(BuildContext context) => VoidCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Accessories', style: VoidTypography.headingMedium),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          const _AccessoryEmptyState()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (context, index) => _AccessoryTile(entries[index]),
          ),
      ],
    ),
  );
}

class _AccessoryEmptyState extends StatelessWidget {
  const _AccessoryEmptyState();

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
      'No linked accessories\nOpen Appearance & Gear to add them.',
      style: VoidTypography.caption,
    ),
  );
}

class _AccessoryTile extends StatelessWidget {
  const _AccessoryTile(this.entry);
  final CharacterAccessoryEntry entry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: context.palette.surfaceElevated,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: context.palette.borderSoft),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.diamond_outlined, color: context.palette.textMuted),
        const SizedBox(height: 5),
        Text(entry.label, style: VoidTypography.caption),
        Text(entry.description, style: VoidTypography.caption),
      ],
    ),
  );
}
