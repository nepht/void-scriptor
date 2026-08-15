import 'package:flutter/material.dart';

import '../domain/sync_models.dart';

/// Compact cloud-sync status indicator (Step 29.16).
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key, required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, tooltip) = switch (status.state) {
      SyncState.idle => (Icons.cloud_outlined, 'Not synced'),
      SyncState.syncing => (Icons.sync, 'Syncing…'),
      SyncState.synced => (Icons.cloud_done, 'Synced'),
      SyncState.error => (Icons.error_outline, 'Sync error'),
      SyncState.conflict => (Icons.warning_amber, 'Sync conflict'),
    };
    return Tooltip(
      message: status.message ?? tooltip,
      child: Icon(icon, size: 18),
    );
  }
}
