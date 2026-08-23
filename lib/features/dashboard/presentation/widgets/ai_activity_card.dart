import 'package:flutter/material.dart';

import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class AiActivityCard extends StatelessWidget {
  const AiActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return VoidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                color: context.palette.primaryBright,
              ),
              const SizedBox(width: 8),
              const Text('AI Activity', style: VoidTypography.headingMedium),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Provider', style: VoidTypography.caption),
          const SizedBox(height: 4),
          const Text('Not connected', style: VoidTypography.title),
          const SizedBox(height: 14),
          const Text(
            'Recent generations will appear here.',
            style: VoidTypography.body,
          ),
        ],
      ),
    );
  }
}
