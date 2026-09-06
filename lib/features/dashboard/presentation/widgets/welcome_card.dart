import 'package:flutter/material.dart';

import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key, required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return VoidCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: context.palette.primary,
            child: const Icon(
              Icons.auto_stories_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $displayName',
                  style: VoidTypography.headingMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Continue your latest novel or open another project.',
                  style: VoidTypography.body,
                ),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, color: context.palette.primaryBright),
        ],
      ),
    );
  }
}
