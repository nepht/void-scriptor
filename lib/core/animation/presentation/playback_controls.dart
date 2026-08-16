import 'package:flutter/material.dart';

/// Play/pause controls (Step 33.18).
class PlaybackControls extends StatelessWidget {
  const PlaybackControls({
    super.key,
    required this.onPlay,
    required this.onPause,
  });

  final VoidCallback onPlay;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: onPlay,
          tooltip: 'Play',
        ),
        IconButton(
          icon: const Icon(Icons.pause),
          onPressed: onPause,
          tooltip: 'Pause',
        ),
      ],
    );
  }
}
