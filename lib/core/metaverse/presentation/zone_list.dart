import 'package:flutter/material.dart';

/// Zone list (Step 42.18).
class ZoneList extends StatelessWidget {
  const ZoneList({super.key, required this.zones});

  final List<String> zones;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final zone in zones)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(zone),
          ),
      ],
    );
  }
}
