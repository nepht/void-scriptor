import 'package:flutter/material.dart';

import '../domain/workspace_tab.dart';

/// Multi-tab bar for the workspace (Step 27.13).
class WorkspaceTabBar extends StatelessWidget {
  const WorkspaceTabBar({
    super.key,
    required this.tabs,
    required this.activeTabId,
    required this.onSelect,
    required this.onClose,
    required this.onCloseOthers,
  });

  final List<WorkspaceTab> tabs;
  final String? activeTabId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onClose;
  final ValueChanged<String> onCloseOthers;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 1),
          itemBuilder: (context, index) {
            final tab = tabs[index];
            final active = tab.id == activeTabId;
            return _Tab(
              tab: tab,
              active: active,
              onSelect: () => onSelect(tab.id),
              onClose: () => onClose(tab.id),
              onCloseOthers: () => onCloseOthers(tab.id),
            );
          },
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.tab,
    required this.active,
    required this.onSelect,
    required this.onClose,
    required this.onCloseOthers,
  });

  final WorkspaceTab tab;
  final bool active;
  final VoidCallback onSelect;
  final VoidCallback onClose;
  final VoidCallback onCloseOthers;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onSelect,
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: active ? colors.surface : colors.surfaceContainerHighest,
          border: Border(
            bottom: BorderSide(
              color: active ? colors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                tab.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            InkWell(
              key: Key('close-tab-${tab.id}'),
              onTap: onClose,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
