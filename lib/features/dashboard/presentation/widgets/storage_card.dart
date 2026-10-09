import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../design_system/typography/void_typography.dart';
import '../../../../design_system/widgets/void_card.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class StorageCard extends StatelessWidget {
  const StorageCard({super.key, this.onManage});

  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    return VoidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage_outlined,
                color: context.palette.primaryBright,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Storage', style: VoidTypography.headingMedium),
              ),
              _StorageStatusPill(),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 18,
                  color: context.palette.textMuted,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Local storage', style: VoidTypography.body),
                ),
              ],
            ),
          ),
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

class _StorageStatusPill extends StatelessWidget {
  const _StorageStatusPill();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.success.withValues(alpha: 0.4)),
      ),
      child: Text(
        'Ready',
        style: VoidTypography.caption.copyWith(color: palette.success),
      ),
    );
  }
}
