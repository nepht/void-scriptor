import 'package:flutter/material.dart';

import 'package:void_scriptor/design_system/theme/void_theme_context.dart';
import 'package:void_scriptor/design_system/typography/void_typography.dart';

/// Sprint 145.23 — Startup Path Simplification.
///
/// Honest local-only status shown while a local (Guest or Offline) session
/// owns the Dashboard: the product works without account, internet, or cloud
/// sync, and the UI must say so explicitly. It must never appear for an
/// authenticated account session.
class LocalOnlyStatusBadge extends StatelessWidget {
  const LocalOnlyStatusBadge({super.key, required this.isLocalOnly});

  final bool isLocalOnly;

  @override
  Widget build(BuildContext context) {
    if (!isLocalOnly) return const SizedBox.shrink();
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.panel,
        border: Border.all(color: palette.borderSoft),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 16, color: palette.textMuted),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Local-only session — no account, no cloud sync.',
              style: VoidTypography.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
