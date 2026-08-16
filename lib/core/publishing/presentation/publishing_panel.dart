import 'package:flutter/material.dart';

/// Publishing overview panel (Step 36.16).
class PublishingPanel extends StatelessWidget {
  const PublishingPanel({
    super.key,
    required this.channelCount,
    required this.latestVersion,
  });

  final int channelCount;
  final String latestVersion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Publishing', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 12),
        Text('Channels: $channelCount'),
        Text('Latest release: $latestVersion'),
      ],
    );
  }
}
