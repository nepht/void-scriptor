import 'package:flutter/material.dart';

import '../../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class CharacterEmptyState extends StatelessWidget {
  const CharacterEmptyState({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.person_search_outlined,
          size: 44,
          color: context.palette.textMuted,
        ),
        const SizedBox(height: 12),
        const Text(
          'No Character Selected',
          style: VoidTypography.headingMedium,
        ),
        const SizedBox(height: 6),
        const Text(
          'Select a character from Explorer to open the workspace.',
          style: VoidTypography.caption,
        ),
      ],
    ),
  );
}
