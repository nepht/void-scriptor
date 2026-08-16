import 'package:flutter/material.dart';

/// Visualizes track names (Step 33.17).
class AnimationTimelineView extends StatelessWidget {
  const AnimationTimelineView({super.key, required this.trackNames});

  final List<String> trackNames;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final name in trackNames)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.timeline, size: 16),
                const SizedBox(width: 8),
                Text(name),
              ],
            ),
          ),
      ],
    );
  }
}
