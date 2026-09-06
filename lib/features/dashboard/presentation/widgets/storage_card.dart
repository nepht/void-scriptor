import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';

class StorageCard extends StatelessWidget {
  const StorageCard({super.key, this.onManage});

  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    return VoidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Storage', style: VoidTypography.headingMedium),
          const SizedBox(height: 10),
          const Text('Local storage', style: VoidTypography.body),
          const SizedBox(height: 6),
          const Text(
            'Usage is calculated per project.',
            style: VoidTypography.caption,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed:
                  onManage ?? () => context.push(AppRoutes.projectStorage),
              child: const Text('Manage local storage'),
            ),
          ),
        ],
      ),
    );
  }
}
