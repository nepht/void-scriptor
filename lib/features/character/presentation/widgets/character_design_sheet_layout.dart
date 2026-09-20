import 'package:flutter/material.dart';

/// Content-width breakpoint: the shell's explorer and inspector are already
/// excluded. The reference sheet gives drawings twice the portrait's width.
class CharacterDesignSheetLayout extends StatelessWidget {
  const CharacterDesignSheetLayout({
    super.key,
    required this.summary,
    required this.turnaround,
    required this.details,
    required this.portrait,
    this.references,
  });

  final Widget summary, turnaround, details, portrait;
  final Widget? references;

  Widget _stack(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: 8),
        children[i],
      ],
    ],
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 21;
      if (constraints.maxWidth < 820 || largeText) {
        return _stack([
          summary,
          portrait,
          turnaround,
          details,
          if (references != null) references!,
        ]);
      }
      // The reference sheet is a fixed two-column composition: the left
      // column is the character information/turnaround strip, while the right
      // column is the portrait/detail strip. Keep this order; do not flatten
      // it into a generic card list.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _stack([summary, turnaround, details])),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: _stack([portrait, if (references != null) references!]),
          ),
        ],
      );
    },
  );
}
