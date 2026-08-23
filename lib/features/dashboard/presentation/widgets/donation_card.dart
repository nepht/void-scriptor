import 'package:flutter/material.dart';

import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class DonationCard extends StatelessWidget {
  const DonationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return VoidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                Icons.favorite_outline,
                color: context.palette.primaryBright,
              ),
              const Text(
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
              OutlinedButton(
                onPressed: () => _feedback(context),
                child: const Text('QRIS'),
              ),
              OutlinedButton(
                onPressed: () => _feedback(context),
                child: const Text('DANA'),
              ),
              OutlinedButton(
                onPressed: () => _feedback(context),
                child: const Text('ShopeePay'),
              ),
              OutlinedButton(
                onPressed: () => _feedback(context),
                child: const Text('Bank Transfer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _feedback(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Donation integration is not configured yet.'),
      ),
    );
  }
}
