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
  });
  final AsyncValue<List<Asset>> stories;
  final String? selectedId;
  final ValueChanged<Asset> onSelected;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    initiallyExpanded: true,
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
      error: (error, _) => [ListTile(dense: true, title: Text('$error'))],
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
