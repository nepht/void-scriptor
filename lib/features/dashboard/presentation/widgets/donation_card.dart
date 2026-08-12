import 'package:flutter/material.dart';

import '../../../../design_system/colors/void_colors.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class DonationCard extends StatelessWidget {
  const DonationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return VoidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.favorite_outline, color: VoidColors.primaryBright),
              Text(
                'Support Void Scriptor',
                style: VoidTypography.headingMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Support development and future updates.',
            style: VoidTypography.body,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(onPressed: () {}, child: const Text('QRIS')),
              OutlinedButton(onPressed: () {}, child: const Text('DANA')),
              OutlinedButton(onPressed: () {}, child: const Text('ShopeePay')),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Bank Transfer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
