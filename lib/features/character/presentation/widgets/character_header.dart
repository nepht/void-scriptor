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
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: context.palette.panelSecondary,
      border: Border(bottom: BorderSide(color: context.palette.borderSoft)),
    ),
    child: Row(
      children: [
        Icon(Icons.chevron_right, size: 16, color: context.palette.textMuted),
        const Text('Characters', style: VoidTypography.breadcrumb),
        Icon(Icons.chevron_right, size: 16, color: context.palette.textMuted),
        Expanded(
          child: Text(
            name,
            style: VoidTypography.breadcrumb.copyWith(
              fontWeight: FontWeight.w600,
              color: context.palette.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: 'Favorite',
          visualDensity: VisualDensity.compact,
          onPressed: () => _feedback(
            context,
            'Favorite is available in the next metadata slice.',
          ),
          icon: const Icon(Icons.star_border, size: 17),
        ),
        IconButton(
          tooltip: 'History',
          visualDensity: VisualDensity.compact,
          onPressed: () =>
              _feedback(context, 'Character history is not persisted yet.'),
          icon: const Icon(Icons.history, size: 17),
        ),
        IconButton(
          tooltip: 'Delete',
          visualDensity: VisualDensity.compact,
          onPressed:
              onDelete ??
              () => _feedback(
                context,
                'Character deletion is not available in this context.',
              ),
          icon: const Icon(Icons.delete_outline, size: 17),
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
