import 'package:flutter/material.dart';

import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class NotificationsCard extends StatelessWidget {
  const NotificationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const VoidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notifications', style: VoidTypography.headingMedium),
          SizedBox(height: 14),
          Text('No new notifications.', style: VoidTypography.body),
        ],
      ),
    );
  }
}
