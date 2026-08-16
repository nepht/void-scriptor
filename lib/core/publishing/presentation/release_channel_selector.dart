import 'package:flutter/material.dart';

/// Release channel selector (Step 36.18).
class ReleaseChannelSelector extends StatelessWidget {
  const ReleaseChannelSelector({super.key, required this.channels});

  final List<String> channels;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final channel in channels)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(channel),
          ),
      ],
    );
  }
}
