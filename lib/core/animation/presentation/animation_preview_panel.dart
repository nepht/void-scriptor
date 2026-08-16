import 'package:flutter/material.dart';

/// Shows current time and animation stats (Step 33.16).
class AnimationPreviewPanel extends StatelessWidget {
  const AnimationPreviewPanel({
    super.key,
    required this.currentTime,
    required this.durationSeconds,
    required this.trackCount,
  });

  final double currentTime;
  final double durationSeconds;
  final int trackCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Animation Preview', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 12),
        Text(
          'Time: ${currentTime.toStringAsFixed(2)}s / ${durationSeconds.toStringAsFixed(2)}s',
        ),
        Text('Tracks: $trackCount'),
      ],
    );
  }
}
