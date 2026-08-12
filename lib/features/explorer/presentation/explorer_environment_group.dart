import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/colors/void_colors.dart';
import '../../environment/domain/environment_model.dart';

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
    leading: const Icon(
      Icons.landscape_outlined,
      size: 16,
      color: VoidColors.textMuted,
    ),
    title: const Text(
      'Environments',
      style: TextStyle(color: VoidColors.textSecondary, fontSize: 12),
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
                      style: const TextStyle(
                        color: VoidColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    selected: selectedId == item.assetId,
                    selectedTileColor: VoidColors.primary.withValues(
                      alpha: 0.12,
                    ),
                    onTap: () => onSelected(item),
                  ),
                )
                .toList(),
    ),
  );
}
