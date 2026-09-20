import 'package:flutter/material.dart';

import '../../../../design_system/theme/void_theme_context.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class CharacterCloseUpDetailCard extends StatelessWidget {
  const CharacterCloseUpDetailCard({super.key, this.imagePaths = const []});

  final List<String> imagePaths;

  @override
  Widget build(BuildContext context) => VoidCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CLOSE UP DETAIL', style: VoidTypography.headingMedium),
        const SizedBox(height: 10),
        SizedBox(
          height: 104,
          child: Row(
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
                    child: Center(
                      child: Icon(
                        const [
                          Icons.face_outlined,
                          Icons.checkroom_outlined,
                          Icons.hexagon_outlined,
                          Icons.auto_awesome_outlined,
                        ][index],
                        color: context.palette.textDisabled,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (imagePaths.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'No close-up references linked.',
            style: VoidTypography.caption.copyWith(
              color: context.palette.textMuted,
            ),
          ),
        ],
      ],
    ),
  );
}
