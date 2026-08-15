import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/layout_controller.dart';
import 'resizable_panel.dart';

/// The dockable shell that composes Explorer, Workspace, and Inspector
/// with resizable + collapsible side panels (Step 27.14).
class WorkspaceLayoutShell extends ConsumerWidget {
  const WorkspaceLayoutShell({
    super.key,
    required this.explorer,
    required this.workspace,
    required this.inspector,
  });

  final Widget explorer;
  final Widget workspace;
  final Widget inspector;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(layoutProvider);
    final notifier = ref.read(layoutProvider.notifier);

    return Row(
      children: [
        if (layout.leftCollapsed)
          CollapsiblePanel(
            collapsed: true,
            collapsedLabel: 'EXPLORER',
            onToggleCollapse: notifier.toggleLeft,
            child: explorer,
          )
        else
          ResizablePanel(
            width: layout.leftWidth,
            minWidth: LayoutController.minWidth,
            maxWidth: 600,
            onResize: notifier.setLeftWidth,
            onToggleCollapse: notifier.toggleLeft,
            child: explorer,
          ),
        Expanded(child: workspace),
        if (layout.rightCollapsed)
          CollapsiblePanel(
            collapsed: true,
            collapsedLabel: 'INSPECTOR',
            onToggleCollapse: notifier.toggleRight,
            child: inspector,
          )
        else
          ResizablePanel(
            width: layout.rightWidth,
            minWidth: LayoutController.minWidth,
            maxWidth: 600,
            onResize: notifier.setRightWidth,
            onToggleCollapse: notifier.toggleRight,
            child: inspector,
          ),
      ],
    );
  }
}
