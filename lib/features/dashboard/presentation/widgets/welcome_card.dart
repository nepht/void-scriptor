import 'package:flutter/material.dart';

import '../../../../design_system/colors/void_colors.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key, required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return VoidCard(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: VoidColors.primary,
            child: Icon(Icons.person_outline, color: Colors.white, size: 26),
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
                  'Continue building your universe.',
                  style: VoidTypography.body,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.auto_awesome_outlined,
            color: VoidColors.primaryBright,
          ),
        ],
      ),
    );
  }
}
