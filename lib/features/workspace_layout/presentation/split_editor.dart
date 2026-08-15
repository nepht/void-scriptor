import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/layout_controller.dart';

/// Split editor that lays out two panes by the layout split ratio (Step 27.16).
///
/// At `splitRatio == 1.0` the secondary pane is collapsed away entirely.
class SplitEditor extends ConsumerWidget {
  const SplitEditor({
    super.key,
    required this.primary,
    required this.secondary,
  });

  final Widget primary;
  final Widget secondary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratio = ref.watch(layoutProvider).splitRatio;
    if (ratio >= 1.0) {
      return primary;
    }
    return Row(
      children: [
        Expanded(flex: (ratio * 100).round(), child: primary),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(flex: ((1.0 - ratio) * 100).round(), child: secondary),
      ],
    );
  }
}

/// Fullscreen preview wrapper with an explicit exit affordance (Step 27.17).
class FullscreenPreview extends StatelessWidget {
  const FullscreenPreview({
    super.key,
    required this.child,
    required this.onExit,
  });

  final Widget child;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          top: 8,
          right: 8,
          child: TextButton.icon(
            onPressed: onExit,
            icon: const Icon(Icons.fullscreen_exit, size: 18),
            label: const Text('Exit fullscreen'),
          ),
        ),
      ],
    );
  }
}
