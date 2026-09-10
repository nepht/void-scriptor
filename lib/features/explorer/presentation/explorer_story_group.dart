import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/project/project_database.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class StoryGroup extends StatelessWidget {
  const StoryGroup({
    super.key,
    required this.stories,
    required this.selectedId,
    required this.onSelected,
    this.focused = false,
    this.onFocused,
    this.onRetry,
  });
  final AsyncValue<List<Asset>> stories;
  final bool focused;
  final VoidCallback? onFocused;
  final String? selectedId;
  final ValueChanged<Asset> onSelected;

  /// BUG-8 (hunt-run171): memungkinkan baris error menawarkan retry
  /// katalog; null berarti tidak ada aksi retry yang tersedia.
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    onExpansionChanged: (_) => onFocused?.call(),
    initiallyExpanded: true,
    backgroundColor: focused
        ? context.palette.primary.withValues(alpha: 0.08)
        : null,
    tilePadding: const EdgeInsets.symmetric(horizontal: 9),
    childrenPadding: const EdgeInsets.only(left: 28),
    leading: Icon(
      Icons.menu_book_outlined,
      size: 16,
      color: context.palette.textMuted,
    ),
    title: Text(
      'Story',
      style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
    ),
    children: stories.when(
      loading: () => [const ListTile(dense: true, title: Text('Loading...'))],
      error: (error, _) => [
        ListTile(
          dense: true,
          minTileHeight: 30,
          title: Text(
            '$error',
            style: TextStyle(color: context.palette.danger, fontSize: 11),
          ),
          trailing: onRetry == null
              ? null
              : IconButton(
                  tooltip: 'Coba lagi',
                  icon: const Icon(Icons.refresh),
                  onPressed: onRetry,
                ),
        ),
      ],
      data: (items) => items.isEmpty
          ? [const ListTile(dense: true, title: Text('No stories yet'))]
          : items
                .map(
                  (item) => ListTile(
                    dense: true,
                    minTileHeight: 30,
                    title: Text(
                      item.name,
                      style: TextStyle(
                        color: context.palette.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    selected: selectedId == item.id,
                    onTap: () => onSelected(item),
                  ),
                )
                .toList(),
    ),
  );
}
