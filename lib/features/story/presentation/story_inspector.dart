import 'package:flutter/material.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class StoryInspector extends StatelessWidget {
  const StoryInspector({super.key, required this.storyId});
  final String storyId;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.palette.panel,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            storyId,
            style:  TextStyle(
              color: context.palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
           Text('Story', style: TextStyle(color: context.palette.textMuted)),
          const Divider(),
           Text(
            'Status\nDraft\n\nCanon\nDraft',
            style: TextStyle(color: context.palette.textSecondary, height: 1.5),
          ),
        ],
      ),
    ),
  );
}
