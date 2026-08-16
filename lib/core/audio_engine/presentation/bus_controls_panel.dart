import 'package:flutter/material.dart';

/// Bus controls panel (Step 34.18).
class BusControlsPanel extends StatelessWidget {
  const BusControlsPanel({super.key, required this.busNames});

  final List<String> busNames;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final name in busNames)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.equalizer, size: 16),
                const SizedBox(width: 8),
                Text(name),
              ],
            ),
          ),
      ],
    );
  }
}
