import 'package:flutter/material.dart';

import '../../../../design_system/typography/void_typography.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class CharacterHeader extends StatelessWidget {
  const CharacterHeader({
    super.key,
    required this.name,
    required this.alias,
    this.onDelete,
  });
  final String name;
  final String alias;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: BoxDecoration(
      color: context.palette.panelSecondary,
      border: Border(bottom: BorderSide(color: context.palette.borderSoft)),
    ),
    child: Row(
      children: [
        Icon(
          Icons.person_outline,
          size: 18,
          color: context.palette.primaryBright,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: VoidTypography.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (alias.isNotEmpty)
                Text(
                  alias,
                  style: VoidTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Favorite',
          onPressed: () => _feedback(
            context,
            'Favorite is available in the next metadata slice.',
          ),
          icon: const Icon(Icons.star_border),
        ),
        IconButton(
          tooltip: 'History',
          onPressed: () =>
              _feedback(context, 'Character history is not persisted yet.'),
          icon: const Icon(Icons.history),
        ),
        IconButton(
          tooltip: 'Delete',
          onPressed:
              onDelete ??
              () => _feedback(
                context,
                'Character deletion is not available in this context.',
              ),
          icon: const Icon(Icons.delete_outline),
        ),
        IconButton(
          tooltip: 'More',
          onPressed: () => _feedback(
            context,
            'Character actions menu is not available yet.',
          ),
          icon: const Icon(Icons.more_horiz),
        ),
      ],
    ),
  );

  void _feedback(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
