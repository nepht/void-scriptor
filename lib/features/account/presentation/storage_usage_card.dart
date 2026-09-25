import 'package:flutter/material.dart';

import '../../../design_system/theme/void_theme_context.dart';
import '../domain/account_center_accessibility.dart';
import '../domain/account_center_design_tokens.dart';
import '../domain/account_center_storage_usage_card.dart';

class StorageUsageCard extends StatelessWidget {
  const StorageUsageCard({super.key, this.data, this.onManage});

  final StorageUsageCardData? data;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final value = data;
    final progress = value?.percentage;
    final message =
        value?.accessibleProgress ??
        'No connected provider is reporting quota or usage.';
    return Container(
      padding: EdgeInsets.all(AccountCenterDesignTokens.card.padding),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(
          AccountCenterDesignTokens.radius.card,
        ),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CLOUD STORAGE USAGE',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          SizedBox(height: AccountCenterDesignTokens.spacing.twoXs),
          Text(
            value?.accountLabel ?? 'Cloud storage accounts',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: AccountCenterDesignTokens.spacing.md),
          Semantics(
            container: true,
            label: 'Storage usage progress: $message',
            value: message,
            child: Row(
              children: [
                Icon(_iconFor(value?.icon)),
                SizedBox(width: AccountCenterDesignTokens.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value == null
                            ? 'Usage unavailable'
                            : '${_formatBytes(value.usedBytes)} used',
                      ),
                      SizedBox(height: AccountCenterDesignTokens.spacing.xs),
                      if (progress != null)
                        ExcludeSemantics(
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight:
                                AccountCenterDesignTokens.progressBar.height,
                          ),
                        )
                      else
                        const Text('Quota unavailable'),
                      SizedBox(height: AccountCenterDesignTokens.spacing.xs),
                      Text(message),
                      if (value != null) Text(value.statusLabel),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AccountCenterDesignTokens.spacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Manage storage'),
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  0,
                  AccountCenterAccessibility.minimumTouchTarget,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(StorageUsageCardIcon? icon) => switch (icon) {
    StorageUsageCardIcon.hardDrive => Icons.storage_outlined,
    StorageUsageCardIcon.archive => Icons.archive_outlined,
    StorageUsageCardIcon.cloud => Icons.cloud_outlined,
    null => Icons.cloud_queue_outlined,
  };

  static String _formatBytes(int bytes) =>
      bytes < 1024 ? '$bytes B' : '${(bytes / 1024).toStringAsFixed(1)} KB';
}
