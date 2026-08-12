import 'package:flutter/material.dart';

import '../../../../design_system/colors/void_colors.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class AiActivityCard extends StatelessWidget {
  const AiActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const VoidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                color: VoidColors.primaryBright,
              ),
              SizedBox(width: 8),
              Text('AI Activity', style: VoidTypography.headingMedium),
            ],
          ),
          SizedBox(height: 16),
          Text('Provider', style: VoidTypography.caption),
          SizedBox(height: 4),
          Text('Not connected', style: VoidTypography.title),
          SizedBox(height: 14),
          Text(
            'Recent generations will appear here.',
            style: VoidTypography.body,
          ),
        ],
      ),
    );
  }
}
