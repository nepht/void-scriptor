import 'package:flutter/material.dart';

import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class MarketplaceCard extends StatelessWidget {
  const MarketplaceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const VoidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Marketplace', style: VoidTypography.headingMedium),
          SizedBox(height: 14),
          Text(
            'Character packs, wardrobe, plugins, themes and prompt packs will appear here.',
            style: VoidTypography.body,
          ),
        ],
      ),
    );
  }
}
