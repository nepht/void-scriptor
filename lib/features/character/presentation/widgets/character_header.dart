import 'package:flutter/material.dart';

import '../../../../design_system/colors/void_colors.dart';
import '../../../../design_system/typography/void_typography.dart';

class CharacterHeader extends StatelessWidget {
  const CharacterHeader({super.key, required this.name, required this.alias});
  final String name;
  final String alias;

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: const BoxDecoration(
      color: VoidColors.panelSecondary,
      border: Border(bottom: BorderSide(color: VoidColors.borderSoft)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.person_outline,
          size: 18,
          color: VoidColors.primaryBright,
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: VoidTypography.title),
            if (alias.isNotEmpty) Text(alias, style: VoidTypography.caption),
          ],
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Favorite',
          onPressed: () {},
          icon: const Icon(Icons.star_border),
        ),
        IconButton(
          tooltip: 'History',
          onPressed: () {},
          icon: const Icon(Icons.history),
        ),
        IconButton(
          tooltip: 'More',
          onPressed: () {},
          icon: const Icon(Icons.more_horiz),
        ),
      ],
    ),
  );
}
