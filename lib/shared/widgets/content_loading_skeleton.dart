import 'package:flutter/material.dart';

/// Content loading skeleton (Steps 26.94/95).
///
/// A non-interactive placeholder used while a section loads. It is a pure
/// visual affordance: no gesture detectors, no ink, no text — so it can never
/// receive input or trigger side effects while data is still arriving.
class ContentLoadingSkeleton extends StatelessWidget {
  const ContentLoadingSkeleton({
    super.key,
    this.rows = 4,
    this.padding = const EdgeInsets.all(16),
  });

  final int rows;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows; i++) ...[
          const SkeletonRow(),
          if (i < rows - 1) const SizedBox(height: 12),
        ],
      ],
    ),
  );
}

class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      height: 16,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
