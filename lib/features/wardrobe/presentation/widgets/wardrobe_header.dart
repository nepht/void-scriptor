import 'package:flutter/material.dart';

import '../../../../design_system/colors/void_colors.dart';

class WardrobeHeader extends StatelessWidget {
  const WardrobeHeader({super.key, required this.name, required this.category});

  final String name;
  final String category;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 500;
      return Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: const BoxDecoration(
          color: VoidColors.panelSecondary,
          border: Border(bottom: BorderSide(color: VoidColors.borderSoft)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.checkroom_outlined,
              color: VoidColors.primaryBright,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: VoidColors.textPrimary),
                  ),
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: VoidColors.textMuted),
                  ),
                ],
              ),
            ),
            if (!compact) ...[
              IconButton(onPressed: () {}, icon: const Icon(Icons.history)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
            ],
          ],
        ),
      );
    },
  );
}
