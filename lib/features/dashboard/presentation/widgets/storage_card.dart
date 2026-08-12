import 'package:flutter/material.dart';

import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class StorageCard extends StatelessWidget {
  const StorageCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const VoidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Storage', style: VoidTypography.headingMedium),
          SizedBox(height: 14),
          LinearProgressIndicator(value: 0.18),
          SizedBox(height: 10),
          Text('1.8 GB of 10 GB used', style: VoidTypography.caption),
        ],
      ),
    );
  }
}
