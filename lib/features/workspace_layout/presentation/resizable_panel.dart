import 'package:flutter/material.dart';

/// A panel that can be resized by dragging its trailing edge (Step 27.9).
class ResizablePanel extends StatelessWidget {
  const ResizablePanel({
    super.key,
    required this.width,
    required this.minWidth,
    required this.maxWidth,
    required this.onResize,
    required this.onToggleCollapse,
    required this.child,
  });

  final double width;
  final double minWidth;
  final double maxWidth;
  final ValueChanged<double> onResize;
  final VoidCallback onToggleCollapse;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Overlay layout: the child receives the full declared width. The
    // previous Row layout squeezed content to width - 48, so fixed-width
    // panels (ExplorerPanel is designed for 245) rendered narrower and
    // native hit targets shifted relative to their painted positions.
    return SizedBox(
      width: width,
      child: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 6,
            child: _ResizeHandle(onResize: onResize, initialWidth: width),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            width: 24,
            height: 24,
            child: IconButton(
              key: const Key('collapse-toggle'),
              iconSize: 14,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 24, height: 24),
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Collapse panel',
              onPressed: onToggleCollapse,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({required this.onResize, required this.initialWidth});

  final ValueChanged<double> onResize;
  final double initialWidth;

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  double? _startX;
  double? _startWidth;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        key: const Key('resize-handle'),
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (details) {
          _startX = details.globalPosition.dx;
          _startWidth = widget.initialWidth;
        },
        onHorizontalDragUpdate: (details) {
          if (_startX == null || _startWidth == null) return;
          final delta = details.globalPosition.dx - _startX!;
          widget.onResize(_startWidth! + delta);
        },
        child: const SizedBox(
          width: 6,
          height: double.infinity,
          child: VerticalDivider(width: 1, thickness: 1),
        ),
      ),
    );
  }
}

/// Collapse/expand wrapper (Step 27.12).
class CollapsiblePanel extends StatelessWidget {
  const CollapsiblePanel({
    super.key,
    required this.collapsed,
    required this.onToggleCollapse,
    required this.collapsedLabel,
    required this.child,
  });

  final bool collapsed;
  final VoidCallback onToggleCollapse;
  final String collapsedLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return SizedBox(
        width: 28,
        child: InkWell(
          onTap: onToggleCollapse,
          child: Tooltip(
            message: 'Expand $collapsedLabel',
            child: Center(
              child: RotatedBox(
                quarterTurns: 1,
                child: Text(
                  collapsedLabel,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return child;
  }
}
