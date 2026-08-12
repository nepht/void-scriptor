import 'package:flutter/material.dart';

import '../../../../design_system/colors/void_colors.dart';
import '../../../../design_system/typography/void_typography.dart';

class CharacterEmptyState extends StatelessWidget {
  const CharacterEmptyState({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.person_search_outlined,
          size: 44,
          color: VoidColors.textMuted,
        ),
        SizedBox(height: 12),
        Text('No Character Selected', style: VoidTypography.headingMedium),
        SizedBox(height: 6),
        Text(
          'Select a character from Explorer to open the workspace.',
          style: VoidTypography.caption,
        ),
      ],
    ),
  );
}
