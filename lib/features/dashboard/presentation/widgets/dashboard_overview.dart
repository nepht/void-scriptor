import 'package:flutter/material.dart';

import '../../../../design_system/theme/void_theme_context.dart';
import '../../../../design_system/typography/void_typography.dart';

/// A compact orientation strip for the dashboard.
///
/// The strip describes the current workspace without inventing cloud or
/// billing state. It is intentionally non-interactive so the dashboard's
/// keyboard order remains focused on real actions.
class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key, required this.isLocalOnly});

  final bool isLocalOnly;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      key: const ValueKey('dashboard-overview-strip'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderSoft),
        gradient: LinearGradient(
          colors: [
            palette.panel,
            Color.alphaBlend(
              palette.primary.withValues(alpha: 0.07),
              palette.panel,
            ),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: palette.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              Icons.auto_stories_outlined,
              color: palette.primaryBright,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Workspace overview',
                      style: VoidTypography.headingMedium,
                    ),
                    _WorkspaceModePill(isLocalOnly: isLocalOnly),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Keep your stories, characters, and worldbuilding in one focused desk.',
                  style: VoidTypography.body.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceModePill extends StatelessWidget {
  const _WorkspaceModePill({required this.isLocalOnly});

  final bool isLocalOnly;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final label = isLocalOnly ? 'Local-first workspace' : 'Account workspace';
    final color = isLocalOnly ? palette.info : palette.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VoidTypography.caption.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
