import 'package:flutter/material.dart';
import '../../../design_system/colors/void_colors.dart';

class StoryInspector extends StatelessWidget {
  const StoryInspector({super.key, required this.storyId});
  final String storyId;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: VoidColors.panel,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            storyId,
            style: const TextStyle(
              color: VoidColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text('Story', style: TextStyle(color: VoidColors.textMuted)),
          const Divider(),
          const Text(
            'Status\nDraft\n\nCanon\nDraft',
            style: TextStyle(color: VoidColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    ),
  );
}
