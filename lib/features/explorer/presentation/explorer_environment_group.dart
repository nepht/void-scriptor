import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../environment/domain/environment_model.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class EnvironmentGroup extends StatelessWidget {
  const EnvironmentGroup({
    super.key,
    required this.environments,
    required this.selectedId,
    required this.onSelected,
  });

  final AsyncValue<List<EnvironmentModel>> environments;
  final String? selectedId;
  final ValueChanged<EnvironmentModel> onSelected;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    initiallyExpanded: true,
    tilePadding: const EdgeInsets.symmetric(horizontal: 9),
    childrenPadding: const EdgeInsets.only(left: 28),
    leading: Icon(
      Icons.landscape_outlined,
      size: 16,
      color: context.palette.textMuted,
    ),
    title: Text(
      'Environments',
      style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
    ),
    children: environments.when(
      loading: () => [const ListTile(dense: true, title: Text('Loading...'))],
      error: (error, _) => [ListTile(dense: true, title: Text('$error'))],
      data: (items) => items.isEmpty
          ? [const ListTile(dense: true, title: Text('No environments yet'))]
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
                    selected: selectedId == item.assetId,
                    selectedTileColor: context.palette.primary.withValues(
                      alpha: 0.12,
                    ),
                    onTap: () => onSelected(item),
                  ),
                )
                .toList(),
    ),
  );
}
